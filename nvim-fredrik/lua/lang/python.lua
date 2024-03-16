local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      vim.notify("Using " .. executable_path)
      return executable_path
    end
  end

  vim.notify("Could not find " .. executable_name .. " in virtual environment.", vim.log.levels.WARN)
  return executable_name
end

local function find_debugpy_python_path()
  -- Return the path to the debugpy python executable if it is
  -- installed in $VIRTUAL_ENV, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/debugpy", true, true)
    if table.concat(paths, ", ") ~= "" then
      local executable_path = vim.env.VIRTUAL_ENV .. "/bin/python"
      vim.notify("Using " .. executable_path)
    end
  end
  local mason_registry = require("mason-registry")
  local path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
  vim.notify("Warning: Using debugpy from Mason.", vim.log.levels.WARN)
  return path
end

local function find_python_executable()
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/python", true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      vim.notify("Using " .. executable_path)
      return executable_path
    end
  elseif vim.fn.filereadable(".venv/bin/python") == 1 then
    local executable_path = vim.fn.expand(".venv/bin/python")
    vim.notify("Using " .. executable_path)
    return executable_path
  end
  vim.notify("No virtual environment found to grab python interpreter from.", vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "88"
    if not vim.g.python3_host_prog then
      vim.g.python3_host_prog = find_python_executable()
      vim.g.python_debugpy_path = find_debugpy_python_path()
      vim.g.python_ruff_path = prefer_bin_from_venv("ruff")
      vim.g.python_mypy_path = prefer_bin_from_venv("mypy")
    end
  end,
})

return {

  {
    "stevearc/conform.nvim",
    ft = { "python" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruff" })
        end,
      },
    },
    opts = function(_, opts)
      opts.formatters_by_ft.python = { "ruff_format" }
      local formatters = require("conform.formatters")
      formatters.ruff_format.command = vim.g.python_ruff_path
    end,
  },

  {
    "mfussenegger/nvim-lint",
    ft = { "python" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruff", "mypy" })
        end,
      },
    },
    opts = function(_, opts)
      opts.linters_by_ft["python"] = { "mypy" }
      opts.linters["mypy"] = {
        cmd = vim.g.pyton_mypy_path,
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    ft = { "python" },
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "pyright", "ruff_lsp" })
        end,
      },
    },
    opts = {
      servers = {
        pyright = {},
        ruff_lsp = {
          on_attach = function(client, bufnr)
            if client.name == "ruff_lsp" then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end,
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    ft = { "python" },
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-python"] = {
        runner = "pytest",
        -- TODO: add coverage...
        args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
        dap = { justMyCode = false },
      }
    end,
  },

  {
    "andythigpen/nvim-coverage",
    ft = { "python" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      auto_reload = true,
      lang = {
        python = {
          coverage_file = vim.fn.getcwd() .. "/coverage.out",
        },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    ft = { "python" },
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
        },
        opts = {
          ensure_installed = { "debugpy" },
        },
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          local dap_python = require("dap-python")
          dap_python.setup(vim.g.python_debugpy_path)
        end,
      },
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "debugpy" })
        end,
      },
    },
  },
}
