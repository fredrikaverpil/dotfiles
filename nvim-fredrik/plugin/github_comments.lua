if not Config.use_codediff then
  return
end

local ns = vim.api.nvim_create_namespace("pr_comments")

local cached_comments = {}
local cached_pending_review_ids = {}
local cached_diff_files = {}
local cached_pr_number = nil
local cached_pr_node_id = nil
local cached_pending_review_node_id = nil

-- --------------------------------------------------------------------------
-- Sign column: show comment indicators
-- --------------------------------------------------------------------------

--- @return integer?
local function resolve_line(comment, side)
  if side == "LEFT" then
    local l = comment.original_line
    if l and l ~= vim.NIL then
      return l
    end
  end
  local l = comment.line
  if l and l ~= vim.NIL then
    return l
  end
  local alt = side == "LEFT" and comment.line or comment.original_line
  if alt and alt ~= vim.NIL then
    return alt
  end
  return nil
end

--- @param comments table[]
--- @param file_path string
--- @return table<string, integer>
local function count_threads(comments, file_path)
  local counts = {}
  for _, c in ipairs(comments) do
    if c.path == file_path and not c.in_reply_to_id then
      local comment_side = c.side or "RIGHT"
      local line = resolve_line(c, comment_side)
      if line then
        local key = string.format("%d:%s", line, comment_side)
        counts[key] = (counts[key] or 0) + 1
      end
    end
  end
  return counts
end

--- @param pending_review_ids table<integer, boolean>
local function place_signs(bufnr, file_path, side, comments, pending_review_ids)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local threads = count_threads(comments, file_path)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  local line_has_published = {}
  local line_has_pending = {}
  for _, c in ipairs(comments) do
    if c.path == file_path and not c.in_reply_to_id then
      local comment_side = c.side or "RIGHT"
      if comment_side == side then
        local l = resolve_line(c, comment_side)
        if l then
          local rid = c.pull_request_review_id
          if rid and pending_review_ids[rid] then
            line_has_pending[l] = true
          else
            line_has_published[l] = true
          end
        end
      end
    end
  end

  for key, _ in pairs(threads) do
    local line_str, comment_side = key:match("^(%d+):(.+)$")
    if comment_side == side then
      local line = tonumber(line_str)
      if line and line >= 1 and line <= line_count then
        local icon = line_has_published[line] and "💬" or "💭"
        vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
          sign_text = icon,
          sign_hl_group = "DiagnosticInfo",
          priority = 1000,
        })
      end
    end
  end
end

--- @return string? file_path
--- @return table? session
local function get_session_file_path()
  local tabpage = vim.api.nvim_get_current_tabpage()
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return nil
  end
  local session = lifecycle.get_session(tabpage)
  if not session then
    return nil
  end

  local file_path = (session.original_path ~= "" and session.original_path)
    or (session.modified_path ~= "" and session.modified_path)
  if not file_path then
    return nil
  end

  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if git_root ~= "" then
    local prefix = git_root .. "/"
    if file_path:sub(1, #prefix) == prefix then
      file_path = file_path:sub(#prefix + 1)
    end
  end

  return file_path, session
end

--- @param pending_review_ids table<integer, boolean>?
local function show_signs_for_session(comments, pending_review_ids)
  local file_path, session = get_session_file_path()
  if not file_path or not session then
    return
  end

  pending_review_ids = pending_review_ids or {}
  place_signs(session.original_bufnr, file_path, "LEFT", comments, pending_review_ids)
  place_signs(session.modified_bufnr, file_path, "RIGHT", comments, pending_review_ids)
end

local function parse_hunk_ranges(patch)
  if not patch then
    return {}
  end
  local hunks = {}
  for left_start, left_count, right_start, right_count in patch:gmatch("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@") do
    table.insert(hunks, {
      left_start = tonumber(left_start),
      left_count = tonumber(left_count) or 1,
      right_start = tonumber(right_start),
      right_count = tonumber(right_count) or 1,
    })
  end
  return hunks
end

local function lines_in_diff(file_path, start_line, end_line, side)
  local file_entry = cached_diff_files[file_path]
  if not file_entry then
    return false
  end
  local hunks = parse_hunk_ranges(file_entry.patch)
  for _, h in ipairs(hunks) do
    local hunk_start, hunk_count
    if side == "LEFT" then
      hunk_start, hunk_count = h.left_start, h.left_count
    else
      hunk_start, hunk_count = h.right_start, h.right_count
    end
    local hunk_end = hunk_start + hunk_count - 1
    if start_line >= hunk_start and end_line <= hunk_end then
      return true
    end
  end
  return false
end

-- --------------------------------------------------------------------------
-- GitHub API helpers
-- --------------------------------------------------------------------------

--- @param query string GraphQL query
--- @param variables table? GraphQL variables
--- @param callback fun(data: table)
--- @param on_error fun(msg: string)?
local function graphql(query, variables, callback, on_error)
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

local function fetch_diff_files(pr_number)
  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/files --paginate", pr_number)
  local stdout_chunks = {}

  vim.fn.jobstart({ "bash", "-c", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        table.insert(stdout_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          local raw = table.concat(stdout_chunks, "")
          if raw ~= "" then
            local ok, files = pcall(vim.json.decode, raw)
            if ok and type(files) == "table" then
              local by_path = {}
              for _, f in ipairs(files) do
                by_path[f.filename] = f
              end
              cached_diff_files = by_path
            end
          end
        end
      end)
    end,
  })
end

local function fetch_review_comments(pr_number, callback)
  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --paginate", pr_number)
  local stdout_chunks = {}

  vim.fn.jobstart({ "bash", "-c", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        table.insert(stdout_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          callback({})
          return
        end
        local raw = table.concat(stdout_chunks, "")
        if raw == "" then
          callback({})
          return
        end
        local ok, items = pcall(vim.json.decode, raw)
        if not ok or type(items) ~= "table" then
          callback({})
          return
        end
        local comments = {}
        for _, c in ipairs(items) do
          table.insert(comments, {
            id = c.id,
            path = c.path,
            body = c.body,
            line = c.line,
            original_line = c.original_line,
            side = c.side or "RIGHT",
            pull_request_review_id = c.pull_request_review_id,
            in_reply_to_id = c.in_reply_to_id,
            user = c.user and c.user.login,
          })
        end
        callback(comments)
      end)
    end,
  })
end

local function fetch_pr_data(callback)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    return
  end
  cached_pr_number = pr_number

  local state = { comments_done = false, reviews_done = false }
  local function try_finish()
    if state.comments_done and state.reviews_done then
      callback(cached_comments, cached_pending_review_ids)
    end
  end

  fetch_diff_files(pr_number)

  fetch_review_comments(pr_number, function(comments)
    cached_comments = comments
    state.comments_done = true
    try_finish()
  end)

  local owner = vim.fn.trim(vim.fn.system("gh repo view --json owner --jq .owner.login"))
  local repo = vim.fn.trim(vim.fn.system("gh repo view --json name --jq .name"))

  local query = [[
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) {
          id
          reviews(first: 100) {
            nodes { id databaseId state }
          }
        }
      }
    }
  ]]

  graphql(query, { owner = owner, repo = repo, pr = tonumber(pr_number) }, function(data)
    local pr = data.repository and data.repository.pullRequest
    if not pr then
      return
    end

    cached_pr_node_id = pr.id

    local pending = {}
    cached_pending_review_node_id = nil
    for _, r in ipairs(pr.reviews and pr.reviews.nodes or {}) do
      if r.state == "PENDING" then
        pending[r.databaseId] = true
        cached_pending_review_node_id = r.id
      end
    end
    cached_pending_review_ids = pending

    state.reviews_done = true
    try_finish()
  end, function(err)
    vim.notify("Failed to fetch PR data: " .. err, vim.log.levels.ERROR)
  end)
end

local function refresh()
  fetch_pr_data(function(comments, pending)
    show_signs_for_session(comments, pending)
  end)
end

local function show_cached()
  if cached_comments and #cached_comments > 0 then
    show_signs_for_session(cached_comments, cached_pending_review_ids)
  end
end

-- --------------------------------------------------------------------------
-- Thread helpers
-- --------------------------------------------------------------------------

--- Returns the root comment and replies at the cursor position, plus context.
--- When multiple root comments exist on the same line, the first is used.
--- @return table? root
--- @return table[] replies
--- @return string? file_path
--- @return string? side
--- @return integer? cursor_line
local function get_thread_at_cursor()
  local cursor_line = vim.fn.line(".")
  local file_path, session = get_session_file_path()
  if not file_path or not session then
    return nil, {}, nil, nil, nil
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local side
  if current_buf == session.original_bufnr then
    side = "LEFT"
  elseif current_buf == session.modified_bufnr then
    side = "RIGHT"
  else
    return nil, {}, nil, nil, nil
  end

  local root = nil
  for _, c in ipairs(cached_comments) do
    if c.path == file_path and not c.in_reply_to_id then
      local comment_side = c.side or "RIGHT"
      if comment_side == side and resolve_line(c, comment_side) == cursor_line then
        root = c
        break
      end
    end
  end

  if not root then
    return nil, {}, file_path, side, cursor_line
  end

  local replies = {}
  for _, c in ipairs(cached_comments) do
    if c.in_reply_to_id == root.id then
      table.insert(replies, c)
    end
  end
  table.sort(replies, function(a, b)
    return a.id < b.id
  end)

  return root, replies, file_path, side, cursor_line
end

-- --------------------------------------------------------------------------
-- Posting comments
-- --------------------------------------------------------------------------

--- @return string? file_path
--- @return integer? start_line
--- @return integer? end_line
--- @return string? side "LEFT" or "RIGHT"
local function get_visual_diff_context()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local tabpage = vim.api.nvim_get_current_tabpage()
  local lifecycle = require("codediff.ui.lifecycle")
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("Not in a codediff session", vim.log.levels.WARN)
    return nil
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local side
  if current_buf == session.original_bufnr then
    side = "LEFT"
  elseif current_buf == session.modified_bufnr then
    side = "RIGHT"
  else
    vim.notify("Cursor is not in a diff buffer", vim.log.levels.WARN)
    return nil
  end

  local file_path = (session.original_path ~= "" and session.original_path)
    or (session.modified_path ~= "" and session.modified_path)
  if not file_path then
    vim.notify("No file path in codediff session", vim.log.levels.WARN)
    return nil
  end

  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if git_root ~= "" then
    local prefix = git_root .. "/"
    if file_path:sub(1, #prefix) == prefix then
      file_path = file_path:sub(#prefix + 1)
    end
  end

  return file_path, start_line, end_line, side
end

local function open_comment_popup(title_prefix, file_path, start_line, end_line, side, on_submit)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"
  vim.b[buf].completion = false

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(15, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = string.format(" %s: %s:%d-%d (%s) ", title_prefix, file_path, start_line, end_line, side),
    title_pos = "center",
  })

  vim.cmd("startinsert")

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local body = vim.fn.trim(table.concat(lines, "\n"))
    if body == "" then
      vim.notify("Empty comment, cancelled", vim.log.levels.WARN)
      close()
      return
    end
    close()
    on_submit(body)
  end

  local opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", close, vim.tbl_extend("force", opts, { desc = "Cancel comment" }))
  vim.keymap.set("n", "<Esc>", close, vim.tbl_extend("force", opts, { desc = "Cancel comment" }))
  vim.keymap.set("n", "<CR>", submit, vim.tbl_extend("force", opts, { desc = "Submit comment" }))
  vim.keymap.set("n", "<C-CR>", submit, vim.tbl_extend("force", opts, { desc = "Submit comment" }))
end

local function build_thread_variables(file_path, start_line, end_line, side, body)
  local vars = {
    path = file_path,
    body = body,
    line = end_line,
    side = side,
  }
  if start_line ~= end_line then
    vars.startSide = side
    vars.startLine = start_line
  end
  return vars
end

local function post_comment(file_path, start_line, end_line, side, body)
  if not cached_pr_node_id then
    vim.notify("No PR data cached — try refreshing first", vim.log.levels.ERROR)
    return
  end

  local variables = build_thread_variables(file_path, start_line, end_line, side, body)
  variables.pullRequestId = cached_pr_node_id

  local query = [[
    mutation($pullRequestId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
      addPullRequestReviewThread(input: {
        pullRequestId: $pullRequestId
        path: $path
        body: $body
        line: $line
        side: $side
        startSide: $startSide
        startLine: $startLine
      }) {
        thread { id }
      }
    }
  ]]

  graphql(query, variables, function()
    vim.notify(string.format("PR comment posted on %s:%d-%d", file_path, start_line, end_line), vim.log.levels.INFO)
    refresh()
  end, function(err)
    vim.notify("Failed to post PR comment: " .. err, vim.log.levels.ERROR)
  end)
end

--- Creates a pending review first if none exists, then adds the thread.
local function post_review_comment(file_path, start_line, end_line, side, body)
  local variables = build_thread_variables(file_path, start_line, end_line, side, body)

  local thread_query = [[
    mutation($pullRequestReviewId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!, $startSide: DiffSide, $startLine: Int) {
      addPullRequestReviewThread(input: {
        pullRequestReviewId: $pullRequestReviewId
        path: $path
        body: $body
        line: $line
        side: $side
        startSide: $startSide
        startLine: $startLine
      }) {
        thread { id }
      }
    }
  ]]

  local function add_thread(review_node_id, is_new_review)
    variables.pullRequestReviewId = review_node_id
    graphql(thread_query, variables, function()
      local msg = is_new_review and string.format("Review started on %s:%d-%d", file_path, start_line, end_line)
        or string.format("Review comment added to review on %s:%d-%d", file_path, start_line, end_line)
      vim.notify(msg, vim.log.levels.INFO)
      refresh()
    end, function(err)
      vim.notify("Failed to add review thread: " .. err, vim.log.levels.ERROR)
    end)
  end

  if cached_pending_review_node_id then
    add_thread(cached_pending_review_node_id, false)
  else
    if not cached_pr_node_id then
      vim.notify("No PR data cached — try refreshing first", vim.log.levels.ERROR)
      return
    end

    local create_query = [[
      mutation($pullRequestId: ID!) {
        addPullRequestReview(input: { pullRequestId: $pullRequestId }) {
          pullRequestReview { id }
        }
      }
    ]]

    graphql(create_query, { pullRequestId = cached_pr_node_id }, function(data)
      local review_id = data.addPullRequestReview
        and data.addPullRequestReview.pullRequestReview
        and data.addPullRequestReview.pullRequestReview.id
      if not review_id then
        vim.notify("Failed to create pending review: no review ID returned", vim.log.levels.ERROR)
        return
      end
      cached_pending_review_node_id = review_id
      add_thread(review_id, true)
    end, function(err)
      vim.notify("Failed to create pending review: " .. err, vim.log.levels.ERROR)
    end)
  end
end

local function post_reply(root_comment_id, body)
  if not cached_pr_number then
    vim.notify("No PR data cached — try refreshing first", vim.log.levels.ERROR)
    return
  end

  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --method POST --input -", cached_pr_number)
  local payload = vim.json.encode({ in_reply_to = root_comment_id, body = body })
  local stderr_chunks = {}

  local job_id = vim.fn.jobstart({ "bash", "-c", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data)
      if data then
        table.insert(stderr_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code ~= 0 then
          vim.notify("Failed to post reply: " .. table.concat(stderr_chunks, ""), vim.log.levels.ERROR)
          return
        end
        vim.notify("Reply posted", vim.log.levels.INFO)
        refresh()
      end)
    end,
  })
  vim.fn.chansend(job_id, payload)
  vim.fn.chanclose(job_id, "stdin")
end

local function open_thread_viewer(thread_comments, root_id, file_path, side, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "wipe"

  local lines = {}
  local function add_comment(c, is_reply)
    local author = c.user or "unknown"
    local header = is_reply and string.format("**@%s** _(reply)_", author) or string.format("**@%s**", author)
    table.insert(lines, header)
    table.insert(lines, "")
    for _, l in ipairs(vim.split(c.body or "", "\n")) do
      table.insert(lines, l)
    end
  end

  add_comment(thread_comments[1], false)
  for i = 2, #thread_comments do
    table.insert(lines, "")
    table.insert(lines, "---")
    table.insert(lines, "")
    add_comment(thread_comments[i], true)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = math.min(90, vim.o.columns - 4)
  local height = math.min(30, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = string.format(" Thread: %s:%d (%s) ", file_path, cursor_line, side),
    title_pos = "center",
    footer = " r: reply  q: close ",
    footer_pos = "center",
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].scrolloff = 3

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", close, vim.tbl_extend("force", opts, { desc = "Close thread viewer" }))
  vim.keymap.set("n", "<Esc>", close, vim.tbl_extend("force", opts, { desc = "Close thread viewer" }))
  vim.keymap.set("n", "r", function()
    close()
    open_comment_popup("Reply", file_path, cursor_line, cursor_line, side, function(body)
      post_reply(root_id, body)
    end)
  end, vim.tbl_extend("force", opts, { desc = "Reply to thread" }))
end

-- --------------------------------------------------------------------------
-- Visual mode entry points (called from keymaps)
-- --------------------------------------------------------------------------

local function pr_comment()
  local file_path, start_line, end_line, side = get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  if not lines_in_diff(file_path, start_line, end_line, side) then
    vim.notify(
      "Selected lines are outside the diff — GitHub only allows comments on changed lines",
      vim.log.levels.WARN
    )
    return
  end
  open_comment_popup("PR comment", file_path, start_line, end_line, side, function(body)
    post_comment(file_path, start_line, end_line, side, body)
  end)
end

local function pr_review_comment()
  local file_path, start_line, end_line, side = get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  if not lines_in_diff(file_path, start_line, end_line, side) then
    vim.notify(
      "Selected lines are outside the diff — GitHub only allows comments on changed lines",
      vim.log.levels.WARN
    )
    return
  end
  open_comment_popup("Review comment", file_path, start_line, end_line, side, function(body)
    post_review_comment(file_path, start_line, end_line, side, body)
  end)
end

local function view_thread()
  local root, replies, file_path, side, cursor_line = get_thread_at_cursor()
  if not root then
    vim.notify("No PR thread at cursor", vim.log.levels.WARN)
    return
  end
  ---@cast file_path string
  ---@cast side string
  ---@cast cursor_line integer

  local thread_comments = { root }
  for _, r in ipairs(replies) do
    table.insert(thread_comments, r)
  end

  open_thread_viewer(thread_comments, root.id, file_path, side, cursor_line)
end

-- --------------------------------------------------------------------------
-- Autocmds and keymaps
-- --------------------------------------------------------------------------

require("lazyload").on_vim_enter(function()
  local group = vim.api.nvim_create_augroup("pr_comment_signs", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = refresh,
  })

  -- CodeDiffOpen fires before async git content is available; this event
  -- guarantees the buffer has lines.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffVirtualFileLoaded",
    callback = show_cached,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffFileSelect",
    callback = function()
      vim.defer_fn(show_cached, 100)
    end,
  })
end)

vim.keymap.set("v", "<leader>gdc", pr_comment, { desc = "Post PR comment" })
vim.keymap.set("v", "<leader>gdC", pr_review_comment, { desc = "Add review comment" })
vim.keymap.set("n", "<leader>gdv", view_thread, { desc = "View PR thread" })
