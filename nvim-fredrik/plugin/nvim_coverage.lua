require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/andythigpen/nvim-coverage" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
  })

  -- Resolved at use time so :cd after startup still finds the profile
  -- written by neotest (plugin/neotest.lua uses the same path).
  local function coverage_file()
    return vim.fs.joinpath(vim.fn.getcwd(), "coverage.out")
  end

  require("coverage").setup({
    auto_reload = true,
    lang = {
      go = { coverage_file = coverage_file },
      python = { coverage_file = coverage_file },
    },
  })

  vim.keymap.set("n", "<leader>tc", "<cmd>Coverage<cr>", { desc = "Test coverage in gutter", silent = true })
  vim.keymap.set(
    "n",
    "<leader>tC",
    "<cmd>CoverageLoad<cr><cmd>CoverageSummary<cr>",
    { desc = "Test coverage summary", silent = true }
  )
end)
