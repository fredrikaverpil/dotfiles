require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("*") },
    { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  })

  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary",
    },
  })
end)
