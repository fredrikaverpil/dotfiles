-- Workaround for Neovim terminal buffers sending per-chunk bracketed paste
-- sequences to child processes. The default vim.paste() handler calls
-- nvim_put() for each ~4KB chunk, and each call wraps the chunk in
-- \e[200~...\e[201~ via terminal_paste(). This produces ~50 rapid-fire
-- bracketed paste events which causes garbled output in TUI apps like
-- Claude Code. The fix is to send a single bracketed paste pair around
-- the entire paste stream.
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
