local M = {}

--- Extract visual selection context from a codediff buffer.
--- @return string? file_path relative path from git root
--- @return integer? start_line first selected line (1-indexed)
--- @return integer? end_line last selected line (1-indexed)
--- @return string? side "LEFT" or "RIGHT"
function M._get_visual_diff_context()
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
    return nil
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
    return nil
  end

  local file_path = session.original_path or session.modified_path
  if not file_path or file_path == "" then
    vim.notify("No file path in codediff session", vim.log.levels.WARN)
    return nil
  end

  return file_path, start_line, end_line, side
end

--- Open a floating window for writing a comment body.
--- @param title_prefix string title prefix for the popup
--- @param file_path string relative path from git root
--- @param start_line integer first selected line (1-indexed)
--- @param end_line integer last selected line (1-indexed)
--- @param side string "LEFT" or "RIGHT"
--- @param on_submit fun(body: string) callback with the comment text
function M._open_comment_popup(title_prefix, file_path, start_line, end_line, side, on_submit)
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
--- @param cmd string the gh api command
--- @param json string JSON payload
--- @param on_success fun() callback on success
--- @param on_error fun(exit_code: integer, stderr: string) callback on failure
function M._gh_api(cmd, json, on_success, on_error)
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

--- Post a standalone PR comment (not part of a review). Visual mode, codediff buffer.
function M.pr_comment()
  local file_path, start_line, end_line, side = M._get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  M._open_comment_popup("PR comment", file_path, start_line, end_line, side, function(body)
    M._post_comment(file_path, start_line, end_line, side, body)
  end)
end

--- Post a review comment (creates a pending review if needed). Visual mode, codediff buffer.
function M.pr_review_comment()
  local file_path, start_line, end_line, side = M._get_visual_diff_context()
  if not file_path then
    return
  end
  ---@cast start_line integer
  ---@cast end_line integer
  ---@cast side string
  M._open_comment_popup("Review comment", file_path, start_line, end_line, side, function(body)
    M._post_review_comment(file_path, start_line, end_line, side, body)
  end)
end

--- Build comment fields for a GitHub API payload.
--- @param file_path string
--- @param start_line integer
--- @param end_line integer
--- @param side string
--- @return table
function M._build_comment_fields(file_path, start_line, end_line, side)
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
--- @param file_path string relative path from git root
--- @param start_line integer first selected line (1-indexed)
--- @param end_line integer last selected line (1-indexed)
--- @param side string "LEFT" or "RIGHT"
--- @param body string comment text
function M._post_comment(file_path, start_line, end_line, side, body)
  local pr_number = vim.fn.trim(vim.fn.system("gh pr view --json number --jq .number 2>/dev/null"))
  if vim.v.shell_error ~= 0 or pr_number == "" then
    vim.notify("No PR found for current branch", vim.log.levels.ERROR)
    return
  end

  local commit_id = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))

  local payload = M._build_comment_fields(file_path, start_line, end_line, side)
  payload.body = body
  payload.commit_id = commit_id

  local cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --input -", pr_number)
  M._gh_api(cmd, vim.json.encode(payload), function()
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
--- @param file_path string relative path from git root
--- @param start_line integer first selected line (1-indexed)
--- @param end_line integer last selected line (1-indexed)
--- @param side string "LEFT" or "RIGHT"
--- @param body string comment text
function M._post_review_comment(file_path, start_line, end_line, side, body)
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

  local comment = M._build_comment_fields(file_path, start_line, end_line, side)
  comment.body = body

  local cmd, json
  if review_id then
    -- Add comment to existing pending review
    comment.commit_id = commit_id
    comment.pull_request_review_id = review_id
    json = vim.json.encode(comment)
    cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/comments --input -", pr_number)
  else
    -- Create a new pending review with this comment
    json = vim.json.encode({
      commit_id = commit_id,
      comments = { comment },
    })
    cmd = string.format("gh api repos/{owner}/{repo}/pulls/%s/reviews --input -", pr_number)
  end

  M._gh_api(cmd, json, function()
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

return M
