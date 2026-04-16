-- Workaround for Neovim terminal buffers not forwarding bracketed paste
-- sequences to child processes. Without this, pasting large text into
-- programs like Claude Code (running in :terminal) results in garbled output.
-- See: https://github.com/neovim/neovim/issues/39110
local orig_paste = vim.paste

vim.paste = function(lines, phase)
  if vim.bo.buftype == "terminal" then
    local chan = vim.b.terminal_job_id
    if chan then
      if phase == 1 or phase == -1 then
        vim.api.nvim_chan_send(chan, "\x1b[200~")
      end
      vim.api.nvim_chan_send(chan, table.concat(lines, "\r"))
      if phase == 3 or phase == -1 then
        vim.api.nvim_chan_send(chan, "\x1b[201~")
      end
      return true
    end
  end
  return orig_paste(lines, phase)
end
