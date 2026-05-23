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

  vim.keymap.set("n", "<leader>tc", "<cmd>Coverage<cr>", { desc = "Test coverage in gutter", silent = true })
  vim.keymap.set("n", "<leader>tC", "<cmd>CoverageLoad<cr><cmd>CoverageSummary<cr>", { desc = "Test coverage summary", silent = true })
end)
