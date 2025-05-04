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
        default = "gemini-2.5-pro-exp-03-25",
        -- default = "gemini-2.0-flash-thinking-exp",
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
local ollima_fn = function()
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
  ollima = ollima_fn,
}

local function save_path()
  local Path = require("plenary.path")
  local p = Path:new(vim.fn.stdpath("data") .. "/codecompanion_chats")
  p:mkdir({ parents = true })
  return p
end

--- Load a saved codecompanion.nvim chat file into a new CodeCompanion chat buffer.
--- Usage: CodeCompanionLoad
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
  local Snacks = require("snacks")

  local function select_adapter(filepath)
    local adapters = vim.tbl_keys(supported_adapters)

    Snacks.picker.select(adapters, {
      prompt = "Select CodeCompanion Adapter",
      format_item = function(item)
        return item
      end,
    }, function(adapter)
      if adapter then
        -- Construct the full file path
        local full_filepath = save_path():joinpath(filepath):absolute()

        -- Check if the file exists before attempting to read it
        if vim.fn.filereadable(full_filepath) == 0 then
          vim.notify("File not found: " .. full_filepath, vim.log.levels.ERROR)
          return
        end

        -- Open new CodeCompanion chat with selected adapter
        vim.cmd("CodeCompanionChat " .. adapter)

        -- Read contents of saved chat file
        local lines = vim.fn.readfile(full_filepath)

        -- Get the current buffer (which should be the new CodeCompanion chat)
        local current_buf = vim.api.nvim_get_current_buf()

        -- Paste contents into the new chat buffer
        vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
      end
    end)
  end

  local function start_picker()
    Snacks.picker.pick({
      source = "files",
      cwd = save_path():absolute(),
      prompt = "Saved CodeCompanion Chats",
      preview = "file",
      format = "file",
      formatters = {
        file = { filename_only = true },
      },
      win = {
        input = {
          keys = {
            ["<leader>r"] = "remove_file",
          },
        },
      },
      actions = {
        remove_file = function(picker)
          -- Ensure the picker object is valid
          if not picker or not picker.current then
            vim.notify("Picker object is invalid or missing", vim.log.levels.ERROR)
            return
          end

          -- Get the current item
          local item = picker:current()
          if item and item.file then
            -- Construct the full file path
            local full_filepath = save_path():joinpath(item.file):absolute()

            -- Attempt to remove the file
            local success, err = os.remove(full_filepath)
            if not success then
              vim.notify("Failed to remove file: " .. full_filepath .. "\nError: " .. err, vim.log.levels.ERROR)
              return
            end

            -- Refresh the picker
            picker:close()
            vim.schedule(function()
              start_picker()
            end)
          else
            vim.notify("No file selected for removal", vim.log.levels.WARN)
          end
        end,
      },
      confirm = function(picker, item)
        picker:close()
        if item and item.file then
          select_adapter(item.file)
        end
      end,
    })
  end

  start_picker()
end, {})

--- Save the current codecompanion.nvim chat buffer to a file in the save_folder.
--- Usage: CodeCompanionSave <filename>.md
---@param opts table
vim.api.nvim_create_user_command("CodeCompanionSave", function(opts)
  local codecompanion = require("codecompanion")
  local chat = codecompanion.buf_get_chat(0)
  if chat == nil then
    vim.notify("CodeCompanionSave should only be called from CodeCompanion chat buffers", vim.log.levels.ERROR)
    return
  end
  if #opts.fargs == 0 then
    vim.notify("CodeCompanionSave requires at least 1 arg to make a file name", vim.log.levels.ERROR)
  end
  local save_name = table.concat(opts.fargs, "-") .. ".md"
  local save_file = save_path():joinpath(save_name)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  save_file:write(table.concat(lines, "\n"), "w")
end, { nargs = "*" })

return {
  {
    "olimorris/codecompanion.nvim",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "folke/snacks.nvim",
      "ravitemer/mcphub.nvim",
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
          provider = "default", -- default|mini_diff
        },
      },
      prompt_library = require("fredrik.utils.llm_prompts").to_codecompanion(),
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_codecompanion_keymaps(),
  },
}
