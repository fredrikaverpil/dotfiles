return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = {
          "nvim-neotest/nvim-nio",
        },
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
        end,
        keys = require("config.keymaps").setup_dap_ui_keymaps(),
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
          -- "mfussenegger/nvim-dap",
        },
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
          local function dap_status()
            return "  " .. require("dap").status()
          end

          opts.dap_status = {
            lualine_component = {
              dap_status,
              cond = function()
                -- return package.loaded["dap"] and require("dap").status() ~= ""
                return require("dap").status() ~= ""
              end,
              color = require("utils.colors").fgcolor("Debug"),
            },
          }
        end,
      },
    },
    config = function(_, opts)
      -- Set nice color highlighting at the stopped line
      -- vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- Show nice icons in gutter instead of the default characters
      for name, sign in pairs(require("utils.defaults").icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, {
          text = sign[1],
          texthl = sign[2] or "DiagnosticInfo",
          linehl = sign[3],
          numhl = sign[3],
        })
      end

      local dap = require("dap")
      if opts.configurations ~= nil then
        local merged = require("utils.table").deep_tbl_extend(dap.configurations, opts.configurations)
        dap.configurations = merged
      end
    end,
    keys = require("config.keymaps").setup_dap_keymaps(),
  },
}
