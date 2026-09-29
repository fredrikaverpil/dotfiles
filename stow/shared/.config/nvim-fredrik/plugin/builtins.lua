require("lazyload").on_vim_enter(function()
  vim.cmd("packadd nvim.undotree")
  vim.cmd("packadd nvim.difftool")
end)
