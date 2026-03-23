local M = {}

local ns = vim.api.nvim_create_namespace("pr_comments")

local cached_comments = {}

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

--- Show comment signs for the current codediff session.
local function show_signs_for_session(comments)
  local tabpage = vim.api.nvim_get_current_tabpage()
  local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
  if not ok then
    return
  end
  local session = lifecycle.get_session(tabpage)
  if not session then
    return
  end

  local file_path = (session.original_path ~= "" and session.original_path)
    or (session.modified_path ~= "" and session.modified_path)
  if not file_path then
    return
  end

  -- GitHub API returns repo-relative paths; strip the repo root so we can match.
  local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  if git_root ~= "" then
    local prefix = git_root .. "/"
    if file_path:sub(1, #prefix) == prefix then
      file_path = file_path:sub(#prefix + 1)
    end
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

M.refresh = refresh

package.loaded["fredrik.plugins.github_comments"] = M

local function show_cached()
  if cached_comments and #cached_comments > 0 then
    show_signs_for_session(cached_comments)
  end
end

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
