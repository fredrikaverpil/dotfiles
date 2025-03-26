-- TODO:
-- - Add all keys?
-- - File selector with snacks.nvim
-- - Web search
-- - MCP servers

return {
  {
    enabled = true,
    "yetone/avante.nvim",
    lazy = true, -- NOTE: required for not invoking `op` on Neovim startup
    -- event = "VeryLazy", -- NOTE: required for not invoking `op` on Neovim startup
    version = false, -- NOTE: the docs says not to set this to "*"
    opts = {

      provider = "claude",

      behaviour = {
        enable_claude_text_editor_tool_mode = true,
      },

      claude = {
        endpoint = "https://api.anthropic.com",
        -- api_key_name = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline",
        api_key_name = "cmd:op read op://Personal/Anthropic/tokens/neovim --session ~/.1password/agent.sock --no-newline",
        -- model = "claude-3-5-sonnet-20241022",
        model = "claude-3-7-sonnet-20250219",
        temperature = 0,
        max_tokens = 4096,
      },

      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
        timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
        temperature = 0,
        max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
        --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      -- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "echasnovski/mini.icons",
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
      {
        "saghen/blink.cmp",
        dependencies = {
          "Kaiser-Yang/blink-cmp-avante",
        },
        opts = {
          sources = {
            -- Add 'avante' to the list
            default = { "avante" },
            providers = {
              avante = {
                module = "blink-cmp-avante",
                name = "Avante",
                opts = {},
              },
            },
          },
        },
        opts_extend = {
          "sources.default",
        },
      },
    },
    cmd = {
      "AvanteAsk",
      "AvanteBuild",
      "AvanteChat",
      "AvanteClear",
      "AvanteEdit",
      "AvanteFocus",
      "AvanteHistory",
      "AvanteModels",
      "AvanteRefresh",
      "AvanteShowRepoMap",
      "AvanteStop",
      "AvanteSwitchFileSectorProvider",
      "AvanteSwitchProvider",
      "AvanteToggle",
      "AvanteToggle",
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteToggle<cr>", desc = "Toggle Avante" },
    },
  },
}
