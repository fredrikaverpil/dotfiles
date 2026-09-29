vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- gha aliases yaml; load the built-in yaml indent
vim.cmd.runtime("indent/yaml.vim")
