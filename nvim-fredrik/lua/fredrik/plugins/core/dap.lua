return {

  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
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
    },
    config = function(_, opts)
      -- Set nice color highlighting at the stopped line
      -- vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- Show nice icons in gutter instead of the default characters
      for name, sign in pairs(require("fredrik.utils.icons").icons.dap) do
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
        local merged = require("fredrik.utils.table").deep_merge(dap.configurations, opts.configurations)
        dap.configurations = merged
      end
    end,
    keys = require("fredrik.config.keymaps").setup_dap_keymaps(),
  },

  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    dependencies = {
      "nvim-neotest/nvim-nio",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          virt_text_pos = "eol",
        },
      },
      {
        "mfussenegger/nvim-dap",
        opts = {},
      },
      {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = {
          "mfussenegger/nvim-dap",
        },
        opts = function(_, opts)
          opts.extensions = { "nvim-dap-ui" }

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
              color = require("fredrik.utils.colors").fgcolor("Debug"),
            },
          }
        end,
      },
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
    keys = require("fredrik.config.keymaps").setup_dap_ui_keymaps(),
  },
}
