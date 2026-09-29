require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/meznaric/key-analyzer.nvim" },
  })

  require("key-analyzer").setup({})
end)
