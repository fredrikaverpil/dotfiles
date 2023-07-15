-- See https://www.lazyvim.org/plugins/extras/dap.core
-- and test.lua for keymaps

return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "debugpy",

        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },

  {
    "mfussenegger/nvim-dap-python",
    dependencies = {
      "mfussenegger/nvim-dap",
    },
    ft = { "python" },
    config = function()
      local dap_python = require("dap-python")

      local function find_debugpy_python_path()
        -- Return the path to the debugpy python executable if it is
        -- installed in $VIRTUAL_ENV, otherwise get it from Mason
        if vim.env.VIRTUAL_ENV then
          local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/debugpy", true, true)
          if table.concat(paths, ", ") ~= "" then
            return vim.env.VIRTUAL_ENV .. "/bin/python"
          end
        end

        local mason_registry = require("mason-registry")
        local path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
        return path
      end

      local dap_python_path = find_debugpy_python_path()
      vim.api.nvim_echo({ { "Using path for dap-python: " .. dap_python_path, "None" } }, false, {})

      dap_python.setup(dap_python_path)
    end,
  },

  -- extend Go extras setup from lazy.lua, with DAP capability
  -- also see https://github.com/LazyVim/LazyVim/pull/1115
  {
    "leoluz/nvim-dap-go",
    dependencies = {
      { "mfussenegger/nvim-dap" },
    },
    ft = { "go" },
    config = true,
    keys = {
      -- workaround, as nvim-dap-go does not have a DAP strategy set up for neotest
      -- see https://github.com/nvim-neotest/neotest-go/issues/12
      { "<leader>tg", "<cmd>lua require('dap-go').debug_test()<CR>", desc = "Debug Nearest (Go)" },
    },
  },
}
