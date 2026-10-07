-- GitHub API helpers for the current branch's pull request, via `gh`.
local M = {}

--- Pull request state shared by the GitHub plugins.
M.cache = {
  --- @type string?
  pr_number = nil,
  --- @type string?
  pr_node_id = nil,
  --- Commit at the head of the pull request on GitHub.
  --- @type string?
  head_oid = nil,
  --- @type string?
  pending_review_node_id = nil,
  --- Database IDs of pending reviews.
  --- @type table<integer, boolean>
  pending_review_ids = {},
}

--- @param query string GraphQL query
--- @param variables table? GraphQL variables
--- @param callback fun(data: table)
--- @param on_error fun(msg: string)?
function M.graphql(query, variables, callback, on_error)
  local json = vim.json.encode({ query = query, variables = variables or {} })
  local stdout_chunks = {}
  local stderr_chunks = {}

  local job_id = vim.fn.jobstart({ "bash", "-c", "gh api graphql --input -" }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        table.insert(stdout_chunks, table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data then
        table.insert(stderr_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local raw = table.concat(stdout_chunks, "")
        if exit_code ~= 0 or raw == "" then
          if on_error then
            on_error(table.concat(stderr_chunks, ""))
          end
          return
        end
        local ok, result = pcall(vim.json.decode, raw)
        if not ok then
          if on_error then
            on_error("Failed to decode GraphQL response")
          end
          return
        end
        if result.errors then
          if on_error then
            on_error(vim.json.encode(result.errors))
          end
          return
        end
        callback(result.data or {})
      end)
    end,
  })
  vim.fn.chansend(job_id, json)
  vim.fn.chanclose(job_id, "stdin")
end

--- Number of the current branch's pull request.
--- @return string?
function M.current_pr_number()
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    return nil
  end
  M.cache.pr_number = pr_number
  return pr_number
end

--- Fetch the pull request's node ID, head commit and pending reviews into the
--- cache.
--- @param pr_number string
--- @param callback fun()
--- @param on_error fun(msg: string)
function M.fetch_reviews(pr_number, callback, on_error)
  local owner = vim.fn.trim(vim.fn.system("gh repo view --json owner --jq .owner.login"))
  local repo = vim.fn.trim(vim.fn.system("gh repo view --json name --jq .name"))

  local query = [[
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          id
          headRefOid
          reviews(first: 100) {
            nodes { id databaseId state }
          }
        }
      }
    }
  ]]

  M.graphql(query, { owner = owner, repo = repo, pr = tonumber(pr_number) }, function(data)
    local pr = data.repository and data.repository.pullRequest
    if not pr then
      return
    end

    M.cache.pr_node_id = pr.id
    M.cache.head_oid = pr.headRefOid

    local pending = {}
    M.cache.pending_review_node_id = nil
    for _, r in ipairs(pr.reviews and pr.reviews.nodes or {}) do
      if r.state == "PENDING" then
        pending[r.databaseId] = true
        M.cache.pending_review_node_id = r.id
      end
    end
    M.cache.pending_review_ids = pending

    callback()
  end, on_error)
end

--- Node ID of the pending review, creating one if none exists.
--- @param callback fun(review_node_id: string, is_new_review: boolean)
--- @param on_error fun(msg: string)
function M.ensure_pending_review(callback, on_error)
  if M.cache.pending_review_node_id then
    callback(M.cache.pending_review_node_id, false)
    return
  end
  if not M.cache.pr_node_id then
    on_error("No PR data cached — try refreshing first")
    return
  end

  local create_query = [[
    mutation($pullRequestId: ID!) {
      addPullRequestReview(input: { pullRequestId: $pullRequestId }) {
        pullRequestReview { id }
      }
    }
  ]]

  M.graphql(create_query, { pullRequestId = M.cache.pr_node_id }, function(data)
    local review_id = data.addPullRequestReview
      and data.addPullRequestReview.pullRequestReview
      and data.addPullRequestReview.pullRequestReview.id
    if not review_id then
      on_error("Failed to create pending review: no review ID returned")
      return
    end
    M.cache.pending_review_node_id = review_id
    callback(review_id, true)
  end, function(err)
    on_error("Failed to create pending review: " .. err)
  end)
end

return M
