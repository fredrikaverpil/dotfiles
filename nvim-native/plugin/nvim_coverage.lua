vim.pack.add({
  { src = "https://github.com/andythigpen/nvim-coverage" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
})

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
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
  end,
})
