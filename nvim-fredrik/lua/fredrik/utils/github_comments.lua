local M = {}

local ns = vim.api.nvim_create_namespace("pr_comments")

local DEBUG = true

local function dbg(fmt, ...)
  if DEBUG then
    vim.notify(string.format("[pr_comments] " .. fmt, ...), vim.log.levels.INFO)
  end
end

--- Cached PR review comments (raw tables from GitHub API).
local cached_comments = {}
local cached_pr_number = nil

--- Fetch PR review comments asynchronously.
--- @param callback fun(comments: table[]) called with the fetched comments
function M._fetch_comments(callback)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    dbg("no PR found (shell_error=%d, pr_number='%s')", vim.v.shell_error, pr_number)
    return
  end
  dbg("fetching comments for PR #%s", pr_number)

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
          dbg("gh api exited with code %d", exit_code)
          return
        end
        local raw = table.concat(stdout_chunks, "")
        if raw == "" then
          dbg("gh api returned empty response")
          cached_comments = {}
          cached_pr_number = pr_number
          callback({})
          return
        end
        local ok, comments = pcall(vim.json.decode, raw)
        if not ok or type(comments) ~= "table" then
          dbg("JSON decode failed: %s", tostring(comments))
          return
        end
        dbg("fetched %d comments for PR #%s", #comments, pr_number)
        cached_comments = comments
        cached_pr_number = pr_number
        callback(comments)
      end)
    end,
  })
end

--- Resolve the display line for a comment on a given side.
--- GitHub uses `line` for RIGHT side and `original_line` for LEFT side.
--- Either can be null (vim.NIL / nil).
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
  -- Fallback: try the other field
  local alt = side == "LEFT" and comment.line or comment.original_line
  if alt and alt ~= vim.NIL then
    return alt
  end
  return nil
end

--- Count comment threads per file+line+side (ignoring replies).
--- @param comments table[]
--- @param file_path string
--- @return table<string, integer> keyed by "line:side"
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
--- @param bufnr integer
--- @param file_path string
--- @param side string "LEFT"|"RIGHT"
--- @param comments PRComment[]
function M._place_signs(bufnr, file_path, side, comments)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    dbg("_place_signs: buffer %d is invalid", bufnr)
    return
  end

  -- Clear existing signs for this buffer
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local threads = count_threads(comments, file_path)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  dbg("_place_signs: buf=%d file='%s' side=%s threads=%d line_count=%d", bufnr, file_path, side, vim.tbl_count(threads), line_count)

  for key, count in pairs(threads) do
    local line_str, comment_side = key:match("^(%d+):(.+)$")
    if comment_side == side then
      local line = tonumber(line_str)
      if line and line >= 1 and line <= line_count then
        local label = count > 1 and string.format("💬%d", count) or "💬"
        dbg("  extmark: buf=%d line=%d side=%s count=%d", bufnr, line, side, count)
        vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
          sign_text = "💬",
          sign_hl_group = "DiagnosticInfo",
          priority = 1000,
        })
      end
    end
  end
end

--- Show comment signs for the current codediff session.
--- @param comments PRComment[]
local function show_signs_for_session(comments)
  local tabpage = vim.api.nvim_get_current_tabpage()
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    dbg("show_signs_for_session: codediff.ui.lifecycle not available")
    return
  end
  local session = lifecycle.get_session(tabpage)
  if not session then
    dbg("show_signs_for_session: no session for tabpage %d", tabpage)
    return
  end

  local file_path = session.original_path or session.modified_path
  if not file_path or file_path == "" then
    dbg("show_signs_for_session: no file_path in session")
    return
  end

  dbg("show_signs_for_session: file='%s' orig_buf=%s mod_buf=%s comments=%d", file_path, tostring(session.original_bufnr), tostring(session.modified_bufnr), #comments)
  M._place_signs(session.original_bufnr, file_path, "LEFT", comments)
  M._place_signs(session.modified_bufnr, file_path, "RIGHT", comments)
end

--- Fetch and show comment signs for the current codediff session.
function M.refresh()
  M._fetch_comments(function(comments)
    show_signs_for_session(comments)
  end)
end

--- Show signs using cached comments (called on file switch).
function M.show_cached()
  if cached_comments and #cached_comments > 0 then
    show_signs_for_session(cached_comments)
  end
end

--- Set up autocmds that auto-show comment signs in codediff buffers.
function M.setup()
  local group = vim.api.nvim_create_augroup("pr_comment_signs", { clear = true })

  -- Fetch comments when a codediff session opens
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = function()
      dbg("autocmd: CodeDiffOpen fired")
      M.refresh()
    end,
  })

  -- Show cached comments when a virtual file (git revision) finishes loading.
  -- CodeDiffOpen fires before async git content is available, so buffers are
  -- still empty at that point.  This event guarantees the buffer has lines.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffVirtualFileLoaded",
    callback = function()
      dbg("autocmd: CodeDiffVirtualFileLoaded fired")
      M.show_cached()
    end,
  })

  -- Show cached comments when switching files in explorer
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffFileSelect",
    callback = function()
      dbg("autocmd: CodeDiffFileSelect fired")
      -- Small delay to let the new buffers load
      vim.defer_fn(function()
        M.show_cached()
      end, 100)
    end,
  })
end

return M
