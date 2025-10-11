return {

  "folke/sidekick.nvim",
  dependencies = {
    "zbirenbaum/copilot.lua",
    "folke/snacks.nvim",
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
      },
      branch = "main",
    },
    {
      "saghen/blink.cmp",
      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      opts = {
        keymap = {
          -- override the tab keymap when using NES
          ["<Tab>"] = {
            "snippet_forward",
            function()
              if require("fredrik.utils.private").is_code_public() then
                return require("sidekick").nes_jump_or_apply()
              end
            end,
            "select_next",
            "fallback",
          },
        },
      },
    },
  },
  ---@class sidekick.Config
  opts = {
    nes = {
      enabled = require("fredrik.utils.private").is_code_public(),
    },
    cli = {
      prompts = {
        -- refactor = "Please refactor {this} to be more maintainable",
        -- security = "Review {file} for security vulnerabilities",
        -- custom = function(ctx)
        --   return "Current file: " .. ctx.buf .. " at line " .. ctx.row
        -- end,
      },
    },
  },
  keys = require("fredrik.config.keymaps").setup_sidekick_keymaps(),
}
