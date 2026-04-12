require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/echasnovski/mini.ai" },
  })

  require("mini.ai").setup({})
end)
