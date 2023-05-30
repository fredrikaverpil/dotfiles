-- Autocmds are automatically loaded on the VeryLazy event
-- Docs: https://www.lazyvim.org/configuration/general
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Python specific options
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.g.python3_host_prog = vim.fn.expand(".venv/bin/python")
    vim.opt_local.colorcolumn = "72,88" -- Ruler at column number
    vim.opt_local.tabstop = 4 -- Number of spaces tabs count for
    vim.opt_local.shiftwidth = 4 -- Size of an indent
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust" },
  callback = function()
    vim.opt_local.colorcolumn = "79" -- Ruler at column number
    vim.opt_local.tabstop = 4 -- Number of spaces tabs count for
    vim.opt_local.shiftwidth = 4 -- Size of an indent
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typescript",
  callback = function()
    vim.opt_local.colorcolumn = "79" -- Ruler at column number
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
