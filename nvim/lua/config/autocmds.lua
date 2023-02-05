-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Python specific options
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python" },
    callback = function()
        vim.opt_local.colorcolumn = "88"  -- Ruler at column number
        vim.opt_local.tabstop = 4 -- Number of spaces tabs count for
        vim.opt_local.shiftwidth = 4 -- Size of an indent
    end,
  })
