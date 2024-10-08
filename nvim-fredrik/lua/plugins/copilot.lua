local function enable_copilot()
  if require("utils.private").enable_ai() then
    if vim.fn.executable("node") == 1 then
      return true
    else
      vim.notify("Node is not available, but required for Copilot.", vim.log.levels.WARN)
      return false
    end
  end
  return false
end

return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      {
        "hrsh7th/nvim-cmp",
        enabled = false,
      },
      {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function(_, opts)
          local function codepilot()
            local icon = require("utils.defaults").icons.kinds.Copilot
            return icon
          end

          -- local function fgcolor(name)
          --   local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
          --   local fg = hl and (hl.fg or hl.foreground)
          --   return fg and { fg = string.format("#%06x", fg) } or nil
          -- end

          local colors = {
            [""] = "Special",
            ["Normal"] = require("utils.colors").fgcolor("Special"),
            ["Warning"] = require("utils.colors").fgcolor("DiagnosticError"),
            ["InProgress"] = require("utils.colors").fgcolor("DiagnosticWarn"),
          }

          opts.copilot = {
            lualine_component = {
              codepilot,
              color = function()
                if not package.loaded["copilot"] then
                  return
                end
                local status = require("copilot.api").status.data
                return colors[status.status] or colors[""]
              end,
            },
          }
        end,
      },
    },
    enabled = enable_copilot(),
    cmd = "Copilot",
    event = "InsertEnter",
    build = ":Copilot auth",
    opts = {
      panel = {
        enabled = true,
        auto_refresh = true,
      },
      suggestion = {
        enabled = true,
        -- use the built-in keymapping for "accept" (<M-l>)
        auto_trigger = true,
        accept = false, -- disable built-in keymapping
      },
      filetypes = {},
    },
    config = function(_, opts)
      require("copilot").setup(opts)

      -- hide copilot suggestions when cmp menu is open
      -- to prevent odd behavior/garbled up suggestions
      local cmp_status_ok, cmp = pcall(require, "cmp")
      if cmp_status_ok then
        cmp.event:on("menu_opened", function()
          vim.b.copilot_suggestion_hidden = true
        end)

        cmp.event:on("menu_closed", function()
          vim.b.copilot_suggestion_hidden = false
        end)
      end
    end,
    keys = require("config.keymaps").setup_copilot_keymaps(),
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    event = "VeryLazy",
    enabled = enable_copilot(),
    branch = "canary", -- while in development
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      debug = false, -- Enable debugging
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
      -- NOTE: cmp is disabled
      -- require("CopilotChat.integrations.cmp").setup()
    end,
    keys = require("config.keymaps").setup_copilot_chat_keymaps(),
  },
}
