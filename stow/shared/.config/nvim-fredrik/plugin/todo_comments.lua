require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/todo-comments.nvim", version = vim.version.range("*") },
  })

  require("todo-comments").setup({})
end)
