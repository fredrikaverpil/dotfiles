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

--- JSON null decodes to vim.NIL, which is truthy.
local function nonnull(v)
  if v == vim.NIL then
    return nil
  end
  return v
end

--- @return string owner
--- @return string repo
local function repo_ref()
  local owner = vim.fn.trim(vim.fn.system("gh repo view --json owner --jq .owner.login"))
  local repo = vim.fn.trim(vim.fn.system("gh repo view --json name --jq .name"))
  return owner, repo
end

--- Fetch the pull request's node ID, head commit and pending reviews into the
--- cache.
--- @param pr_number string
--- @param callback fun()
--- @param on_error fun(msg: string)
function M.fetch_reviews(pr_number, callback, on_error)
  local owner, repo = repo_ref()

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

--- Review comments on the pull request, including the viewer's pending ones.
---
--- Each comment carries its thread's position: `line` is nil once the thread
--- is outdated, `start_line` is set for ranges, and replies point at the
--- thread's first comment.
--- @param pr_number string
--- @param callback fun(comments: table[])
--- @param on_error fun(msg: string)
function M.fetch_review_comments(pr_number, callback, on_error)
  local owner, repo = repo_ref()

  local query = [[
    query($owner: String!, $repo: String!, $pr: Int!, $after: String) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          reviewThreads(first: 100, after: $after) {
            nodes {
              path
              diffSide
              line
              originalLine
              startLine
              originalStartLine
              comments(first: 100) {
                nodes {
                  databaseId
                  body
                  author { login }
                  pullRequestReview { databaseId }
                }
              }
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  ]]

  local comments = {}
  local function fetch_page(after)
    local variables = { owner = owner, repo = repo, pr = tonumber(pr_number), after = after }
    M.graphql(query, variables, function(data)
      local threads = data.repository and data.repository.pullRequest and data.repository.pullRequest.reviewThreads
      if not threads then
        on_error("No review threads returned for PR #" .. pr_number)
        return
      end
      for _, t in ipairs(threads.nodes or {}) do
        local root_id = nil
        for _, c in ipairs(t.comments.nodes or {}) do
          local review = nonnull(c.pullRequestReview)
          local author = nonnull(c.author)
          table.insert(comments, {
            id = c.databaseId,
            path = t.path,
            body = c.body,
            line = t.line,
            original_line = t.originalLine,
            start_line = t.startLine,
            original_start_line = t.originalStartLine,
            side = nonnull(t.diffSide) or "RIGHT",
            pull_request_review_id = review and review.databaseId,
            in_reply_to_id = root_id,
            user = author and author.login,
          })
          root_id = root_id or c.databaseId
        end
      end
      if threads.pageInfo.hasNextPage then
        fetch_page(threads.pageInfo.endCursor)
      else
        callback(comments)
      end
    end, on_error)
  end
  fetch_page(nil)
end

--- Viewed state of every file in the pull request, keyed by path.
--- @param pr_number string
--- @param callback fun(states: table<string, "VIEWED"|"UNVIEWED"|"DISMISSED">)
--- @param on_error fun(msg: string)
function M.fetch_viewed_files(pr_number, callback, on_error)
  local owner, repo = repo_ref()

  local query = [[
    query($owner: String!, $repo: String!, $pr: Int!, $after: String) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          files(first: 100, after: $after) {
            nodes { path viewerViewedState }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    }
  ]]

  local states = {}
  local function fetch_page(after)
    local variables = { owner = owner, repo = repo, pr = tonumber(pr_number), after = after }
    M.graphql(query, variables, function(data)
      local files = data.repository and data.repository.pullRequest and data.repository.pullRequest.files
      if not files then
        on_error("No files returned for PR #" .. pr_number)
        return
      end
      for _, f in ipairs(files.nodes or {}) do
        states[f.path] = f.viewerViewedState
      end
      if files.pageInfo.hasNextPage then
        fetch_page(files.pageInfo.endCursor)
      else
        callback(states)
      end
    end, on_error)
  end
  fetch_page(nil)
end

--- Mark or unmark a pull request file as viewed by the current user.
--- @param path string
--- @param viewed boolean
--- @param callback fun()
--- @param on_error fun(msg: string)
function M.set_file_viewed(path, viewed, callback, on_error)
  if not M.cache.pr_node_id then
    on_error("No PR data cached — try refreshing first")
    return
  end

  local mutation = viewed and "markFileAsViewed" or "unmarkFileAsViewed"
  local query = string.format(
    [[
      mutation($pullRequestId: ID!, $path: String!) {
        %s(input: { pullRequestId: $pullRequestId, path: $path }) {
          pullRequest { id }
        }
      }
    ]],
    mutation
  )

  M.graphql(query, { pullRequestId = M.cache.pr_node_id, path = path }, function()
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
