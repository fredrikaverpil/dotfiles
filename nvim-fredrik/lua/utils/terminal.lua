M = {}

function M.toggle_terminal_native()
  -- If the terminal buffer doesn't exist or is no longer valid...
  if not vim.g.terminal_buf or not vim.api.nvim_buf_is_valid(vim.g.terminal_buf) then
    -- Create a new terminal buffer
    vim.g.terminal_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(vim.g.terminal_buf, "buftype", "nofile") -- FIXME: deprecated
    vim.api.nvim_buf_call(vim.g.terminal_buf, function()
      vim.cmd("terminal")
    end)
  end
  -- If the terminal window doesn't exist or is no longer valid...
  if not vim.g.terminal_win or not vim.api.nvim_win_is_valid(vim.g.terminal_win) then
    -- Create a new split window and display the terminal buffer in it
    vim.cmd("split")
    vim.g.terminal_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(vim.g.terminal_win, vim.g.terminal_buf)
  else
    -- If the terminal window is the current window, hide it
    if vim.api.nvim_get_current_win() == vim.g.terminal_win then
      vim.api.nvim_win_hide(vim.g.terminal_win)
    else -- Otherwise, switch to the terminal window
      vim.api.nvim_set_current_win(vim.g.terminal_win)
    end
  end
end

function M.toggle_fterm()
  require("FTerm").toggle()
end

function M.toggle_toggleterm()
  -- NOTE: this requires toggleterm
  local cwd = vim.fn.getcwd()
  local cwd_folder_name = vim.fn.fnamemodify(cwd, ":t")

  local cmd = ":ToggleTerm size=40 dir=" .. cwd .. " direction=horizontal name=" .. cwd_folder_name
  vim.cmd(cmd)
end

return M
