-- See https://www.lazyvim.org/plugins/extras/dap.core
-- and test.lua for keymaps

return {

  -- fix error seen in https://github.com/LazyVim/LazyVim/discussions/821
  -- {
  --   "theHamsta/nvim-dap-virtual-text",
  --   config = function()
  --     require("nvim-dap-virtual-text").setup({
  --       display_callback = function(variable, buf, stackframe, node, options) end,
  --     })
  --   end,
  -- },

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      -- "theHamsta/nvim-dap-virtual-text",
    },

    config = function()
      -- vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
      local dap = require("dap")

      -- Python DAP
      -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#Python
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          -- The first three options are required by nvim-dap
          type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
          request = "launch",
          name = "Launch file",

          -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
          program = "${file}", -- This configuration will launch the current file if used.
          pythonPath = function()
            -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
            -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
            -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
            return os.getenv("VIRTUAL_ENV") .. "/bin/python" or "/usr/bin/env python"
          end,
          justMyCode = false,
        },
      }
    end,
  },
}
