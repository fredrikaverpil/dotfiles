local M = {}

local ns = vim.api.nvim_create_namespace("pr_comments")

local cached_comments = {}

-- --------------------------------------------------------------------------
-- Sign column: show comment indicators
-- --------------------------------------------------------------------------

--- Resolve the display line for a comment on a given side.
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

--- Count comment threads per file+line+side (ignoring replies).
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

--- Place signs on a buffer for the given file path and side.
local function place_signs(bufnr, file_path, side, comments)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local threads = count_threads(comments, file_path)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for key, _ in pairs(threads) do
    local line_str, comment_side = key:match("^(%d+):(.+)$")
    if comment_side == side then
      local line = tonumber(line_str)
      if line and line >= 1 and line <= line_count then
        vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
          sign_text = "💬",
          sign_hl_group = "DiagnosticInfo",
          priority = 1000,
        })
      end
    end
  end
end

--- Get the repo-relative file path for the current codediff session.
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

  -- GitHub API returns repo-relative paths; strip the repo root so we can match.
  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if git_root ~= "" then
    local prefix = git_root .. "/"
    if file_path:sub(1, #prefix) == prefix then
      file_path = file_path:sub(#prefix + 1)
    end
  end

  return file_path, session
end

--- Show comment signs for the current codediff session.
local function show_signs_for_session(comments)
  local file_path, session = get_session_file_path()
  if not file_path or not session then
    return
  end

  place_signs(session.original_bufnr, file_path, "LEFT", comments)
  place_signs(session.modified_bufnr, file_path, "RIGHT", comments)
end

--- Fetch PR review comments asynchronously.
local function fetch_comments(callback)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    return
  end

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
          return
        end
        local raw = table.concat(stdout_chunks, "")
        if raw == "" then
          cached_comments = {}
          callback({})
          return
        end
        local decode_ok, comments = pcall(vim.json.decode, raw)
        if not decode_ok or type(comments) ~= "table" then
          return
        end
        cached_comments = comments
        callback(comments)
      end)
    end,
  })
end

local function refresh()
  fetch_comments(function(comments)
    show_signs_for_session(comments)
  end)
end

local function show_cached()
  if cached_comments and #cached_comments > 0 then
    show_signs_for_session(cached_comments)
  end
end

-- --------------------------------------------------------------------------
-- Posting comments
-- --------------------------------------------------------------------------

--- Extract visual selection context from a codediff buffer.
--- @return string? file_path relative path from git root
--- @return integer? start_line first selected line (1-indexed)
--- @return integer? end_line last selected line (1-indexed)
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

  return file_path, start_line, end_line, side
end

--- Open a floating window for writing a comment body.
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

--- Run a gh api command with JSON payload piped via stdin.
local function gh_api(cmd, json, on_success, on_error)
  local stderr_chunks = {}
  local job_id = vim.fn.jobstart({ "bash", "-c", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          on_success()
        else
          on_error(exit_code, table.concat(stderr_chunks, ""))
        end
      end)
    end,
    on_stderr = function(_, data)
      if data then
        table.insert(stderr_chunks, table.concat(data, "\n"))
      end
    end,
  })
  vim.fn.chansend(job_id, json)
  vim.fn.chanclose(job_id, "stdin")
end

--- Build comment fields for a GitHub API payload.
local function build_comment_fields(file_path, start_line, end_line, side)
  local fields = {
    path = file_path,
    side = side,
    line = end_line,
  }
  if start_line ~= end_line then
    fields.start_line = start_line
    fields.start_side = side
  end
  return fields
end

--- Post a standalone comment to GitHub via `gh api`.
local function post_comment(file_path, start_line, end_line, side, body)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    vim.notify("No PR found for current branch", vim.log.levels.ERROR)
    return
  end

  local commit_id = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))

  local payload = build_comment_fields(file_path, start_line, end_line, side)
  payload.body = body
  payload.commit_id = commit_id

  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --input -", pr_number)
  gh_api(cmd, vim.json.encode(payload), function()
    vim.notify(string.format("PR comment posted on %s:%d-%d", file_path, start_line, end_line), vim.log.levels.INFO)
  end, function(exit_code, stderr)
    vim.notify("Failed to post PR comment (exit " .. exit_code .. ")", vim.log.levels.ERROR)
    if stderr ~= "" then
      vim.notify("gh: " .. stderr, vim.log.levels.ERROR)
    end
  end)
end

--- Post a review comment to GitHub. Creates a pending review if none exists,
--- otherwise adds the comment to the existing pending review.
local function post_review_comment(file_path, start_line, end_line, side, body)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    vim.notify("No PR found for current branch", vim.log.levels.ERROR)
    return
  end

  local commit_id = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))

  -- Check for an existing pending review
  local reviews_json = vim.fn.system(
    string.format("gh api repos/{owner}/{repo}/pulls/%s/reviews 2>/dev/null", pr_number)
  )
  local review_id = nil
  if vim.v.shell_error == 0 and reviews_json ~= "" then
    local ok, reviews = pcall(vim.json.decode, reviews_json)
    if ok and type(reviews) == "table" then
      for _, review in ipairs(reviews) do
        if review.state == "PENDING" then
          review_id = review.id
          break
        end
      end
    end
  end

  local comment = build_comment_fields(file_path, start_line, end_line, side)
  comment.body = body

  local cmd, json
  if review_id then
    comment.commit_id = commit_id
    comment.pull_request_review_id = review_id
    json = vim.json.encode(comment)
    cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --input -", pr_number)
  else
    json = vim.json.encode({
      commit_id = commit_id,
      comments = { comment },
    })
    cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/reviews --input -", pr_number)
  end

  gh_api(cmd, json, function()
    local action = review_id and "added to review" or "review started"
    vim.notify(
      string.format("Review comment %s on %s:%d-%d", action, file_path, start_line, end_line),
      vim.log.levels.INFO
    )
  end, function(exit_code, stderr)
    vim.notify("Failed to post review comment (exit " .. exit_code .. ")", vim.log.levels.ERROR)
    if stderr ~= "" then
      vim.notify("gh: " .. stderr, vim.log.levels.ERROR)
    end
  end)
end

-- --------------------------------------------------------------------------
-- Public API (for keymaps)
-- --------------------------------------------------------------------------

function M.refresh()
  refresh()
end

function M.pr_comment()
  local file_path, start_line, end_line, side = get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  open_comment_popup("PR comment", file_path, start_line, end_line, side, function(body)
    post_comment(file_path, start_line, end_line, side, body)
  end)
end

function M.pr_review_comment()
  local file_path, start_line, end_line, side = get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  open_comment_popup("Review comment", file_path, start_line, end_line, side, function(body)
    post_review_comment(file_path, start_line, end_line, side, body)
  end)
end

package.loaded["fredrik.plugins.github_comments"] = M

return {
  {
    name = "github-comments",
    dir = ".",
    event = "User CodeDiffOpen",
    config = function()
      local group = vim.api.nvim_create_augroup("pr_comment_signs", { clear = true })

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "CodeDiffOpen",
        callback = refresh,
      })

      -- CodeDiffOpen fires before async git content is available, so buffers are
      -- still empty at that point. This event guarantees the buffer has lines.
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

      -- The CodeDiffOpen event that triggered this plugin load has already
      -- fired, so the autocmd above won't catch it. Fetch immediately.
      refresh()
    end,
  },
}
