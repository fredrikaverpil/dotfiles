local function is_vertex_available()
  -- Check if the environment variables for Google Cloud are set
  return os.getenv("GOOGLE_CLOUD_PROJECT") and os.getenv("GOOGLE_CLOUD_LOCATION")
end

local function default_provider()
  if is_vertex_available() then
    return "vertex"
  else
    return "claude"
  end
end

local function vertex_endpoint()
  if is_vertex_available() then
    return "https://"
      .. os.getenv("GOOGLE_CLOUD_LOCATION")
      .. "-aiplatform.googleapis.com/v1/projects/"
      .. os.getenv("GOOGLE_CLOUD_PROJECT")
      .. "/locations/"
      .. os.getenv("GOOGLE_CLOUD_LOCATION")
      .. "/publishers/google/models"
  else
    return nil
  end
end

return {
  {
    enabled = true,
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
      provider = default_provider(),
      providers = {
        vertex = {
          endpoint = vertex_endpoint(),
          model = "gemini-2.5-pro",
          timeout = 30000,
          extra_request_body = {
            generationConfig = {
              temperature = 0.75,
              -- maxOutputTokens = 8192, -- Note: The max value for gemini-1.5-pro is 8192
            },
          },
        },
      },

      web_search_engine = {
        provider = "tavily", -- tavily, serpapi, searchapi, google or kagi
      },

      input = {
        provider = "snacks",
      },

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
