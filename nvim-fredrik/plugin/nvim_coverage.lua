require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/andythigpen/nvim-coverage" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
  })

  require("coverage").setup({
    auto_reload = true,
    lang = {
      go = {
        coverage_file = vim.fn.getcwd() .. "/coverage.out",
      },
      python = {
        coverage_file = vim.fn.getcwd() .. "/coverage.out",
      },
    },
  })
end)
