local anthropic_fn = function()
  local anthropic_config = {
    env = { api_key = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline" },
  }
  return require("codecompanion.adapters").extend("anthropic", anthropic_config)
end

local openai_fn = function()
  local openai_config = {
    env = { api_key = "cmd:op read op://Personal/OpenAI/tokens/neovim --no-newline" },
  }
  return require("codecompanion.adapters").extend("openai", openai_config)
end

local gemini_fn = function()
  local gemini_config = {
    env = { api_key = "cmd:op read op://Personal/Google/tokens/gemini --no-newline" },
    schema = {
      model = {
        default = "gemini-2.5-pro-preview-05-06",
      },
    },
  }
  return require("codecompanion.adapters").extend("gemini", gemini_config)
end

local deepseek_fn = function()
  local deepseek_config = {
    env = { api_key = "cmd:op read op://Personal/DeepSeek/tokens/neovim --no-newline" },
    -- schema = {
    --   model = {
    --     default = "deepseek-reasoner",
    --   },
    -- },
  }
  return require("codecompanion.adapters").extend("deepseek", deepseek_config)
end

--- Ollama config for CodeCompanion.
local ollama_fn = function()
  return require("codecompanion.adapters").extend("ollima", {
    schema = {
      model = {
        default = "gemma3:1b",
        -- default = "deepseek-r1:7b",
        -- default = "llama3.1:7b",
        -- default = "codellama:7b",
      },
      num_ctx = {
        default = 16384,
      },
      num_predict = {
        default = -1,
      },
    },
  })
end

local supported_adapters = {
  anthropic = anthropic_fn,
  openai = openai_fn,
  gemini = gemini_fn,
  deepseek = deepseek_fn,
  ollama = ollama_fn,
}

return {
  {
    "olimorris/codecompanion.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-treesitter/nvim-treesitter",
        opts = {
          ensure_installed = { codecompanion = "markdown" },
        },
      },
      "folke/snacks.nvim",
      "ravitemer/mcphub.nvim",
      "ravitemer/codecompanion-history.nvim",
      {
        "saghen/blink.cmp",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
          sources = {
            default = { "codecompanion" },
            providers = {
              codecompanion = {
                name = "CodeCompanion",
                module = "codecompanion.providers.completion.blink",
                enabled = true,
              },
            },
          },
        },
        opts_extend = {
          "sources.default",
        },
      },
    },
    opts = {

      opts = {
        send_code = function()
          if vim.fn.filereadable(".llm_ok") == 1 then
            -- override by adding a .llm_ok file in the project root
            return true
          end

          return require("fredrik.utils.private").is_ai_enabled()
        end,
      },

      adapters = supported_adapters,

      strategies = {
        chat = {
          adapter = "anthropic",
          slash_commands = {
            buffer = { opts = { provider = "snacks" } },
            file = { opts = { provider = "snacks" } },
            help = { opts = { provider = "snacks" } },
            symbols = { opts = { provider = "snacks" } },
          },
        },
        inline = {
          adapter = "anthropic",
        },
        cmd = {
          adapter = "anthropic",
        },
      },

      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
        history = {
          enabled = true,
          opts = {
            -- Keymap to open history from chat buffer (default: gh)
            -- keymap = "gh",
            -- Keymap to save the current chat manually (when auto_save is disabled)
            -- save_chat_keymap = "sc",
            -- Save all chats by default (disable to save only manually using 'sc')
            auto_save = true,
            -- Number of days after which chats are automatically deleted (0 to disable)
            expiration_days = 0,
            -- Picker interface ("telescope" or "snacks" or "fzf-lua" or "default")
            picker = "snacks",
            -- Automatically generate titles for new chats
            auto_generate_title = true,
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = false,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            ---Enable detailed logging for history extension
            enable_logging = false,
          },
        },
      },

      display = {
        chat = {
          show_settings = true,
          icons = {
            pinned_buffer = " ",
            watched_buffer = "👀 ",
          },
        },
        action_palette = {
          provider = "default", -- default|telescope|mini_pick
        },
        diff = {
          enabled = true,
        },
      },
      prompt_library = require("fredrik.utils.llm_prompts").to_codecompanion(),
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
    -- https://codecompanion.olimorris.dev/usage/chat-buffer/#keymaps
    keys = require("fredrik.config.keymaps").setup_codecompanion_keymaps(),
  },
}
