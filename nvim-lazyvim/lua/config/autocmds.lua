-- Autocmds are automatically loaded on the VeryLazy event
-- Docs: https://www.lazyvim.org/configuration/general
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function find_python_executable()
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/python", true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      vim.api.nvim_echo({ { "Using path for python: " .. executable_path, "None" } }, false, {})
      return executable_path
    end
  elseif vim.fn.filereadable(".venv/bin/python") == 1 then
    local executable_path = vim.fn.expand(".venv/bin/python")
    vim.api.nvim_echo({ { "Using path for python: " .. executable_path, "None" } }, false, {})
    return executable_path
  end
  vim.api.nvim_echo({ { "No python executable found (see autocmds.lua)", "WarningMsg" } }, false, {})
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.g.python3_host_prog = find_python_executable() -- python executable
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

-- see lint.lua
-- vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost" }, {
--   callback = function()
--     require("lint").try_lint()
--   end,
-- })
