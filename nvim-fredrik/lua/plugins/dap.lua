return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        opts = {},
        config = function(_, opts)
          -- setup dap config by VsCode launch.json file
          -- require("dap.ext.vscode").load_launchjs()
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open({})
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close({})
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close({})
          end

          require("config.keymaps").setup_dap_ui_keymaps()
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "mason.nvim",
        cmd = { "DapInstall", "DapUninstall" },
        opts = {
          -- Makes a best effort to setup the various debuggers with
          -- reasonable debug configurations
          automatic_installation = true,

          -- You can provide additional configuration to the handlers,
          -- see mason-nvim-dap README for more information
          handlers = {},

          -- You'll need to check that you have the required things installed
          -- online, please don't ask me how to install them :)
          ensure_installed = {
            -- Update this to ensure that you have the debuggers for the langs you want
          },
        },
      },
      {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
          local function dap()
            return "  " .. require("dap").status()
          end

          local function fgcolor(name)
            local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
            local fg = hl and (hl.fg or hl.foreground)
            return fg and { fg = string.format("#%06x", fg) } or nil
          end

          opts.dap = {
            lualine_component = {
              dap,
              color = function()
                return fgcolor("Debug")
              end,
              cond = function()
                return package.loaded["dap"] and require("dap").status() ~= ""
              end,
            },
          }
        end,
      },
    },

    config = function(_, opts)
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(require("utils.defaults").icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] })
      end

      require("config.keymaps").setup_dap_keymaps()
    end,
  },
}
