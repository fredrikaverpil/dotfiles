-- TODO:
-- - Add all keys?
-- - File selector with snacks.nvim
-- - Web search
-- - MCP servers

return {
  {
    enabled = false,
    "yetone/avante.nvim",
    lazy = true, -- NOTE: required for not invoking `op` on Neovim startup
    -- event = "VeryLazy", -- NOTE: required for not invoking `op` on Neovim startup
    version = false, -- NOTE: the docs says not to set this to "*"
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "echasnovski/mini.icons",
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      "HakonHarnes/img-clip.nvim", -- for image pasting
      "ravitemer/mcphub.nvim",
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
    opts = {

      provider = "claude",
      cursor_applying_provider = "claude",

      behaviour = {
        enable_claude_text_editor_tool_mode = true,
        enable_cursor_planning_mode = false, -- NOTE: uses Aider's method to planing when false, but is picky about the model chosen
      },

      web_search_engine = {
        provider = "tavily", -- tavily, serpapi, searchapi, google or kagi
      },

      file_selector = {
        provider = "telescope",
      },

      -- NOTE: when using mcphub.nvim, disable tools defined here
      --
      -- custom_tools = {
      --   {
      --     name = "run_go_tests", -- Unique name for the tool
      --     description = "Run Go unit tests and return results", -- Description shown to AI
      --     command = "go test -v ./...", -- Shell command to execute
      --     param = { -- Input parameters (optional)
      --       type = "table",
      --       fields = {
      --         {
      --           name = "target",
      --           description = "Package or directory to test (e.g. './pkg/...' or './internal/pkg')",
      --           type = "string",
      --           optional = true,
      --         },
      --       },
      --     },
      --     returns = { -- Expected return values
      --       {
      --         name = "result",
      --         description = "Result of the fetch",
      --         type = "string",
      --       },
      --       {
      --         name = "error",
      --         description = "Error message if the fetch was not successful",
      --         type = "string",
      --         optional = true,
      --       },
      --     },
      --     func = function(params, on_log, on_complete) -- Custom function to execute
      --       local target = params.target or "./..."
      --       return vim.fn.system(string.format("go test -v %s", target))
      --     end,
      --   },
      -- },

      -- The custom_tools type supports both a list and a function that returns a list.
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,

      -- The system_prompt type supports both a string and a function that returns a string. Using a function here allows dynamically updating the prompt with mcphub
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub:get_active_servers_prompt()
      end,

      claude = {
        endpoint = "https://api.anthropic.com",
        api_key_name = "cmd:op read op://Personal/Anthropic/tokens/neovim --no-newline",
        -- model = "claude-3-5-sonnet-20241022",
        model = "claude-3-7-sonnet-latest",
        temperature = 0,
        max_tokens = 4096,
        disable_tools = false,
      },

      openai = {
        endpoint = "https://api.openai.com/v1",
        api_key_name = "cmd:op read op://Personal/OpenAI/tokens/neovim --no-newline",
        model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
        timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
        temperature = 0,
        max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
        --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
      },

      ollama = {
        endpoint = "http://127.0.0.1:11434", -- Note that there is no /v1 at the end.
        model = "gemma3:4b",
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
      {
        "<leader>aa",
        function()
          -- Open the Avante chat window, without preselecint any files.
          require("avante.api").ask({ without_selection = true })
        end,
        desc = "Toggle Avante",
      },
    },
  },
}
