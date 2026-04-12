vim.cmd([[packadd nvim.undotree]])

return {

  {
    "mbbill/undotree",
    enabled = false, -- replaced by built-in :Undotree in neovim 0.12
    lazy = true,
    cmd = "UndotreeToggle",
  },
}
