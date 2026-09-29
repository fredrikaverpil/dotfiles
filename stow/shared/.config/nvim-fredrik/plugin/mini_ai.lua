require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/echasnovski/mini.ai", version = vim.version.range("*") },
  })

  require("mini.ai").setup({})
end)
