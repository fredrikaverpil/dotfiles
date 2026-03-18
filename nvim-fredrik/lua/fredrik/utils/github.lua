local M = {}

--- Open a floating window for writing a PR review comment, then post it via `gh`.
--- Must be called from visual mode inside a codediff diff buffer.
function M.pr_review_comment()
  -- Capture visual selection range before leaving visual mode
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  -- Get codediff session
  local tabpage = vim.api.nvim_get_current_tabpage()
  local lifecycle = require("codediff.ui.lifecycle")
  local session = lifecycle.get_session(tabpage)
  if not session then
    vim.notify("Not in a codediff session", vim.log.levels.WARN)
    return
  end

  -- Determine which side the cursor is on
  local current_buf = vim.api.nvim_get_current_buf()
  local side
  if current_buf == session.original_bufnr then
    side = "LEFT"
  elseif current_buf == session.modified_bufnr then
    side = "RIGHT"
  else
    vim.notify("Cursor is not in a diff buffer", vim.log.levels.WARN)
    return
  end

  local file_path = session.original_path or session.modified_path
  if not file_path or file_path == "" then
    vim.notify("No file path in codediff session", vim.log.levels.WARN)
    return
  end

  -- Open comment input popup
  M._open_comment_popup(file_path, start_line, end_line, side)
end

--- Open a floating window for writing the comment body.
--- @param file_path string relative path from git root
--- @param start_line number first selected line (1-indexed)
--- @param end_line number last selected line (1-indexed)
--- @param side string "LEFT" or "RIGHT"
function M._open_comment_popup(file_path, start_line, end_line, side)
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
    title = string.format(" PR comment: %s:%d-%d (%s) ", file_path, start_line, end_line, side),
    title_pos = "center",
  })

  -- Start in insert mode
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
    M._post_review_comment(file_path, start_line, end_line, side, body)
  end

  -- Keymaps inside the popup
  local opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", close, vim.tbl_extend("force", opts, { desc = "Cancel comment" }))
  vim.keymap.set("n", "<Esc>", close, vim.tbl_extend("force", opts, { desc = "Cancel comment" }))
  vim.keymap.set("n", "<CR>", submit, vim.tbl_extend("force", opts, { desc = "Submit comment" }))
  vim.keymap.set("n", "<C-CR>", submit, vim.tbl_extend("force", opts, { desc = "Submit comment" }))
end

--- Post the review comment to GitHub via `gh api`.
--- @param file_path string relative path from git root
--- @param start_line number first selected line (1-indexed)
--- @param end_line number last selected line (1-indexed)
--- @param side string "LEFT" or "RIGHT"
--- @param body string comment text
function M._post_review_comment(file_path, start_line, end_line, side, body)
  -- Get PR number
  local pr_number = vim.fn.system("gh pr view --json number --jq .number 2>/dev/null")
  if vim.v.shell_error ~= 0 or pr_number == "" then
    vim.notify("No PR found for current branch", vim.log.levels.ERROR)
    return
  end
  pr_number = vim.fn.trim(pr_number)

  -- commit_id must be the latest commit in the PR; `side` tells GitHub which diff side
  local commit_id = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))

  -- Build API payload
  local payload = {
    body = body,
    commit_id = commit_id,
    path = file_path,
    side = side,
    line = end_line,
  }

  -- Multi-line comment
  if start_line ~= end_line then
    payload.start_line = start_line
    payload.start_side = side
  end

  local json = vim.json.encode(payload)

  -- Post via gh api (pipe JSON via stdin to avoid shell quoting issues)
  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --input -", pr_number)

  local job_id = vim.fn.jobstart({ "bash", "-c", cmd }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          vim.notify(
            string.format("PR comment posted on %s:%d-%d", file_path, start_line, end_line),
            vim.log.levels.INFO
          )
        else
          vim.notify("Failed to post PR comment (exit " .. exit_code .. ")", vim.log.levels.ERROR)
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local msg = table.concat(data, "\n")
        if msg ~= "" then
          vim.schedule(function()
            vim.notify("gh: " .. msg, vim.log.levels.ERROR)
          end)
        end
      end
    end,
  })

  -- Feed JSON payload via stdin
  vim.fn.chansend(job_id, json)
  vim.fn.chanclose(job_id, "stdin")
end

return M
