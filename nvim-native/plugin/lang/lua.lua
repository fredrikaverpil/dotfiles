vim.pack.add({
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  { src = "https://github.com/jbyuki/one-small-step-for-vimkind" }, -- Lua DAP adapter
})

require("lazyload").on_vim_enter(function()
  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary",
    },
  })
end)
