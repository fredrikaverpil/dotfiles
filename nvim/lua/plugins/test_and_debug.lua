return {

  -- neotest
  {
    "nvim-neotest/neotest",
    keys = {
      { "<leader>rr", ":lua require('neotest').run.run()<CR>", desc = "Run nearest test" },
      { "<leader>rl", ":lua require('neotest').run.run_last()<CR>", desc = "Run last test" },
      { "<leader>rf", ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>", desc = "Run tests in file" },
      { "<leader>rs", ":lua require('neotest').summary.toggle()<CR>", desc = "Run test summary" },
      { "<leader>ro", ":lua require('neotest').output.open({ enter = true })<CR>", desc = "Run test output" },
      { "<leader>rp", ":lua require('neotest').output_panel.toggle()<CR>", desc = "Run test output panel" },

      -- debugging via nvim-dap
      -- { "<leader>rd", ":lua require('neotest').run.run({ strategy = 'dap' })<CR>", desc = "Debug nearest test" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            -- runner = "pytest",
          }),
          require("neotest-plenary"),
          require("neotest-vim-test")({
            -- ignore file types for installed adapters (or use allow_file_types)
            ignore_file_types = { "python", "vim", "lua" },
          }),
        },
      })
    end,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
      { "antoinemadec/FixCursorHold.nvim" },

      -- python
      {
        "nvim-neotest/neotest-python",
        dependencies = {
          { "nvim-neotest/neotest-plenary" },
          { "nvim-neotest/neotest-vim-test" },
        },
      },
    },
  },
}
