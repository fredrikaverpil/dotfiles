return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      -- {
      --   "hrsh7th/nvim-cmp",
      --   enabled = true,
      -- },
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
            ["Normal"] = require("utils.colors").fgcolor("Special"),
            ["Warning"] = require("utils.colors").fgcolor("DiagnosticError"),
            ["InProgress"] = require("utils.colors").fgcolor("DiagnosticWarn"),
            ["Offline"] = require("utils.colors").fgcolor("Comment"),
            ["Error"] = require("utils.colors").fgcolor("Error"),
          }

          opts.copilot = {
            lualine_component = {
              codepilot,
              color = function()
                if not package.loaded["copilot"] or vim.g.custom_copilot_status == "disabled" then
                  -- offline
                  return colors["Offline"]
                else
                  -- online
                  local status = require("copilot.api").status
                  if status.data.status ~= "" or status.data.message ~= "" then
                    return colors[status.data.status] or colors["Error"]
                  else
                    return colors["InProgress"]
                  end
                end
              end,
            },
          }
        end,
      },
    },
    enabled = true,
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
      filetypes = {
        sh = function()
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
            -- disable for .env files
            return false
          end
          return true
        end,
      },
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
    enabled = true,
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
