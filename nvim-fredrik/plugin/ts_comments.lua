require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/ts-comments.nvim" },
  })

  require("ts-comments").setup()
end)
