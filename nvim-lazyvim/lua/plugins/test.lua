return {

  -- neotest, also set up via lazy.lua.
  -- go here for full config, including keymaps: https://www.lazyvim.org/plugins/extras/test.core
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
      { "adrigzr/neotest-mocha" },
      { "vim-test/vim-test" },
    },

    keys = {
      {
        "<leader>tT",
        ":lua require('neotest').run.run({ suite = true })<CR>",
        desc = "Run all tests (override LazyVim)",
      },
    },
    config = function()
      -- set up neotest with neodev
      require("neodev").setup({
        -- also see .neoconf.json
        library = { plugins = { "neotest" }, types = true },
      })

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

          require("neotest-mocha")({
            -- https://github.com/adrigzr/neotest-mocha
            filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
            command = "npm test --",
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          }),

          require("neotest-vim-test")({
            -- https://github.com/nvim-neotest/neotest-vim-test
            ignore_file_types = { "python", "vim", "lua", "rust" },
          }),
        },
      })
    end,
  },
}
