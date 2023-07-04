-- See https://www.lazyvim.org/plugins/extras/dap.core
-- and test.lua for keymaps

return {

  {
    "mfussenegger/nvim-dap-python",

    dependencies = {
      "mfussenegger/nvim-dap",
    },

    ft = { "python" },

    config = function()
      local dap_python = require("dap-python")

      local function find_debugpy_python_path()
        -- Return the path to the debugpy python executable if it is installed in $VIRTUAL_ENV, otherwise get it from Mason
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
}
