-- add 2 commands:
--    CodeCompanionSave [space delimited args]
--    CodeCompanionLoad
-- Save will save current chat in a md file named 'space-delimited-args.md'
-- Load will use a telescope filepicker to open a previously saved chat

-- create a folder to store our chats
local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data") -- ~/.local/share/<NVIM_APPNAME>
local save_folder = Path:new(data_path, "codecompanion_chats")
if not save_folder:exists() then
  save_folder:mkdir({ parents = true })
end

-- telescope picker for our saved chats
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
  local t_builtin = require("telescope.builtin")
  local t_actions = require("telescope.actions")
  local t_action_state = require("telescope.actions.state")

  local function start_picker()
    t_builtin.find_files({
      prompt_title = "Saved CodeCompanion Chats | <c-d>: delete",
      cwd = save_folder:absolute(),
      attach_mappings = function(_, map)
        map("i", "<c-d>", function(prompt_bufnr)
          local selection = t_action_state.get_selected_entry()
          local filepath = selection.path or selection.filename
          os.remove(filepath)
          t_actions.close(prompt_bufnr)
          start_picker()
        end)
        return true
      end,
    })
  end
  start_picker()
end, {})

-- save current chat, `CodeCompanionSave foo bar baz` will save as 'foo-bar-baz.md'
vim.api.nvim_create_user_command("CodeCompanionSave", function(opts)
  local codecompanion = require("codecompanion")
  local success, chat = pcall(function()
    return codecompanion.buf_get_chat(0)
  end)
  if not success or chat == nil then
    vim.notify("CodeCompanionSave should only be called from CodeCompanion chat buffers", vim.log.levels.ERROR)
    return
  end
  if #opts.fargs == 0 then
    vim.notify("CodeCompanionSave requires at least 1 arg to make a file name", vim.log.levels.ERROR)
  end
  local save_name = table.concat(opts.fargs, "-") .. ".md"
  local save_path = Path:new(save_folder, save_name)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  save_path:write(table.concat(lines, "\n"), "w")
end, { nargs = "*" })

--- Anthropic config for CodeCompanion.
local anthropic_fn = function()
  local anthropic_config = {
    env = { api_key = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline" },
  }
  return require("codecompanion.adapters").extend("anthropic", anthropic_config)
end

--- OpenAI config for CodeCompanion.
local openai_fn = function()
  local openai_config = {
    env = { api_key = "cmd:op read op://Personal/OpenAI/tokens/neovim --no-newline" },
  }
  return require("codecompanion.adapters").extend("openai", openai_config)
end

--- Gemini config for CodeCompanion.
local gemini_fn = function()
  local gemini_config = {
    env = { api_key = "cmd:op read op://Personal/Google/tokens/gemini --no-newline" },
    schema = {
      model = {
        default = "gemini-2.0-flash-exp",
      },
    },
  }
  return require("codecompanion.adapters").extend("gemini", gemini_config)
end

--- Ollama config for CodeCompanion.
local ollama_fn = function()
  return require("codecompanion.adapters").extend("ollama", {
    schema = {
      model = {
        default = "llama3.1:8b",
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

return {
  {
    "olimorris/codecompanion.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
      {
        "stevearc/dressing.nvim",
        opts = {},
      },
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
      adapters = {
        anthropic = anthropic_fn,
        openai = openai_fn,
        gemini = gemini_fn,
        ollama = ollama_fn,
      },
      strategies = {
        chat = {
          slash_commands = {
            ["buffer"] = {
              provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
            },

            ["file"] = {
              opts = {
                provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
              },
            },

            ["help"] = {
              opts = {
                provider = "fzf_lua", -- telescope|mini_pick|fzf_lua
              },
            },

            ["symbols"] = {
              opts = {
                provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_codecompanion_keymaps(),
  },
}
