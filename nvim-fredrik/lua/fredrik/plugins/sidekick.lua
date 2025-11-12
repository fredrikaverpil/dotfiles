return {

  "folke/sidekick.nvim",
  dependencies = {
    "zbirenbaum/copilot.lua",
    {
      "folke/snacks.nvim",
      opts = {
        picker = {
          actions = {
            sidekick_send = function(...)
              return require("sidekick.cli.snacks").send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = {
                  "sidekick_send",
                  mode = { "n", "i" },
                },
              },
            },
          },
        },
      },
    },
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
      ---@type table<string, sidekick.cli.Config|{}>
      tools = {
        -- https://code.claude.com/docs/en/iam
        claude = {
          cmd = {
            "claude",
            "--continue",
            "--allowedTools=mcp__github",
            "--allowedTools=mcp__serena",
            "--allowedTools=Bash(gh:*)",
            "--allowedTools=RunBash(go:*)",
            "--allowedTools=Read(~/code)",
          },
        },
      },
    },
  },
  keys = require("fredrik.config.keymaps").setup_sidekick_keymaps(),
}
