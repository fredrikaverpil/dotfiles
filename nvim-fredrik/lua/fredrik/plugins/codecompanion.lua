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

local supported_adapters = {
  anthropic = anthropic_fn,
  openai = openai_fn,
  gemini = gemini_fn,
  ollama = ollama_fn,
}

-- add 2 commands:
--    CodeCompanionSave [space delimited args]
--    CodeCompanionLoad
-- Save will save current chat in a md file named 'space-delimited-args.md'
-- Load will use a telescope filepicker to open a previously saved chat and open it in a new chat buffer

-- create a folder to store our chats
local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data") -- ~/.local/share/<NVIM_APPNAME>
local save_folder = Path:new(data_path, "codecompanion_chats")
if not save_folder:exists() then
  save_folder:mkdir({ parents = true })
end

-- telescope picker for our saved chats
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
  local function select_adapter(filepath)
    local fzf = require("fzf-lua")
    local adapters = vim.tbl_keys(supported_adapters)

    fzf.fzf_exec(adapters, {
      prompt = "Select CodeCompanion Adapter> ",
      actions = {
        ["default"] = function(selected)
          local adapter = selected[1]
          -- Open new CodeCompanion chat with selected adapter
          vim.cmd("CodeCompanionChat " .. adapter)

          -- Read contents of saved chat file
          local lines = vim.fn.readfile(filepath)

          -- Get the current buffer (which should be the new CodeCompanion chat)
          local current_buf = vim.api.nvim_get_current_buf()

          -- Paste contents into the new chat buffer
          vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
        end,
      },
    })
  end

  local function start_picker()
    local fzf = require("fzf-lua")
    local files = vim.fn.glob(save_folder:absolute() .. "/*", false, true)

    fzf.fzf_exec(files, {
      prompt = "Saved CodeCompanion Chats | <c-r>: remove >",
      previewer = "builtin",
      actions = {
        ["default"] = function(selected)
          if #selected > 0 then
            local filepath = selected[1]
            select_adapter(filepath)
          end
        end,
        ["ctrl-r"] = function(selected)
          if #selected > 0 then
            local filepath = selected[1]
            os.remove(filepath)
            -- Refresh the picker
            start_picker()
          end
        end,
      },
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

      opts = {
        -- WARNING: send_code does not accept a function. It should be evaluated each time CWD changes.
        send_code = require("fredrik.utils.private").is_ai_enabled(),
      },

      adapters = supported_adapters,

      strategies = {
        chat = {
          adapter = "anthropic",
          slash_commands = {
            ["buffer"] = {
              opts = {
                provider = "fzf_lua", -- default|telescope|mini_pick|fzf_lua
              },
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
        inline = {
          adapter = "copilot",
        },
        cmd = {
          adapter = "copilot",
        },
      },
      display = {
        chat = {
          show_settings = true,
        },
        action_palette = {
          provider = "default", -- default|telescope|mini_pick
        },
        diff = {
          provider = "default", -- default|mini_diff
        },
      },
      prompt_library = {
        -- https://github.com/olimorris/codecompanion.nvim/blob/main/doc/RECIPES.md
        ["Code review"] = {
          strategy = "chat",
          description = "Code review",
          prompts = {
            {
              role = "system",
              content = [[Analyze the code for:

### CODE QUALITY
* Function and variable naming (clarity and consistency)
* Code organization and structure
* Documentation and comments
* Consistent formatting and style

### RELIABILITY
* Error handling and edge cases
* Resource management
* Input validation

### MAINTAINABILITY
* Code duplication (but don't overdo it with DRY, some duplication is fine)
* Single responsibility principle
* Modularity and dependencies
* API design and interfaces
* Configuration management

### PERFORMANCE
* Algorithmic efficiency
* Resource usage
* Caching opportunities
* Memory management

### SECURITY
* Input sanitization
* Authentication/authorization
* Data validation
* Known vulnerability patterns

### TESTING
* Unit test coverage
* Integration test needs
* Edge case testing
* Error scenario coverage

### POSITIVE HIGHLIGHTS
* Note any well-implemented patterns
* Highlight good practices found
* Commend effective solutions

Format findings as markdown and with:
- Issue: [description]
- Impact: [specific impact]
- Suggestion: [concrete improvement with code example/suggestion]

              ]],
            },
            {
              role = "user",
              content = "Please review provided code.\n" .. "#buffer #lsp",
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
