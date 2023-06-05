return {

  {
    "folke/neodev.nvim",
    config = function()
      require("neodev").setup({
        library = { plugins = { "neotest" }, types = true },
      })
    end,
  },

  -- neotest, also set up via lazy.lua.
  -- go here for full config, including keymaps: https://www.lazyvim.org/plugins/extras/test.core
  {
    "nvim-neotest/neotest",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
      { "antoinemadec/FixCursorHold.nvim" },

      -- adapters
      { "nvim-neotest/neotest-vim-test" },
      { "nvim-neotest/neotest-python" },
      { "rouge8/neotest-rust" },
      { "adrigzr/neotest-mocha" },
      { "vim-test/vim-test" },
    },

    config = function()
      require("neotest").setup({

        -- https://github.com/nvim-neotest/neotest-python
        adapters = {
          require("neotest-python")({
            runner = "pytest",
            args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
          }),

          require("neotest-rust")({
            -- https://github.com/rouge8/neotest-rust
            --
            -- requires nextest, which can be installed via "cargo binstall:
            -- https://github.com/cargo-bins/cargo-binstall
            -- https://nexte.st/book/pre-built-binaries.html
            args = { "--no-capture" },
          }),

          -- TODO: there is an issue where neotest-mocha attempts to run tests for Python:
          -- https://github.com/adrigzr/neotest-mocha/issues/7
          --
          -- require("neotest-mocha")({
          --   -- https://github.com/adrigzr/neotest-mocha
          --   filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          --   command = "npm test --",
          --   env = { CI = true },
          --   cwd = function(path)
          --     return vim.fn.getcwd()
          --   end,
          -- }),

          require("neotest-vim-test")({
            -- https://github.com/nvim-neotest/neotest-vim-test
            ignore_file_types = { "python", "vim", "lua", "rust" },
          }),
        },
      })
    end,
  },
}
