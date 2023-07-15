return {

  {
    "nvim-neotest/neotest",

    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
      { "antoinemadec/FixCursorHold.nvim" },
      { "folke/neodev.nvim" },

      -- adapters
      { "nvim-neotest/neotest-vim-test" },
      { "nvim-neotest/neotest-python" },
      { "rouge8/neotest-rust" },
      { "nvim-neotest/neotest-go" },
      { "adrigzr/neotest-mocha" },
      { "vim-test/vim-test" },
    },

    keys = {
      {
        "<leader>tS",
        ":lua require('neotest').run.run({ suite = true })<CR>",
        desc = "Run all tests in suite",
      },
    },

    opts = {
      adapters = {
        ["neotest-python"] = {
          -- https://github.com/nvim-neotest/neotest-python
          runner = "pytest",
          args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
          -- dap = { justMyCode = false },
        },
        ["neotest-go"] = {
          -- see lazy.lua
        },
        -- ["neotest-rust"] = {
        --   -- see lazy.lua
        --   -- https://github.com/rouge8/neotest-rust
        --   --
        --   -- requires nextest, which can be installed via "cargo binstall":
        --   -- https://github.com/cargo-bins/cargo-binstall
        --   -- https://nexte.st/book/pre-built-binaries.html
        -- },
        ["neotest-mocha"] = {
          -- https://github.com/adrigzr/neotest-mocha
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          command = "npm test --",
          env = { CI = true },
          cwd = function(_) -- skipped arg is path
            return vim.fn.getcwd()
          end,
        },
        ["neotest-vim-test"] = {
          -- https://github.com/nvim-neotest/neotest-vim-test
          ignore_file_types = { "python", "vim", "lua", "rust", "go" },
        },
      },
    },
  },
}
