local M = {}

--- @class TerminalState
--- @field buf number|nil Buffer handle
--- @field win number|nil Window handle
local terminal_state = {
  buf = nil,
  win = nil,
}

--- Toggles the terminal window visibility
--- If terminal doesn't exist, creates a new one
--- If terminal exists but is hidden, shows it
--- If terminal is visible, hides it
--- @return nil
function M.toggle_split_terminal()
  -- If terminal buffer exists, check if it's visible
  if terminal_state.buf and vim.api.nvim_buf_is_valid(terminal_state.buf) then
    local wins = vim.api.nvim_list_wins()
    local is_visible = false

    -- Find if terminal window is visible
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_get_buf(win) == terminal_state.buf then
        is_visible = true
        terminal_state.win = win
        break
      end
    end

    if is_visible then
      -- Hide the terminal
      vim.api.nvim_win_hide(terminal_state.win)
    else
      -- Show the terminal in a new split
      vim.cmd.split()
      vim.cmd.wincmd("J")
      vim.api.nvim_win_set_buf(0, terminal_state.buf)
      vim.api.nvim_win_set_height(0, 15)
      terminal_state.win = vim.api.nvim_get_current_win()
    end
  else
    -- Create new terminal
    vim.cmd.new()
    vim.cmd.wincmd("J")
    vim.cmd.term()
    vim.api.nvim_win_set_height(0, 15)
    terminal_state.buf = vim.api.nvim_get_current_buf()
    terminal_state.win = vim.api.nvim_get_current_win()
  end
end

return M
