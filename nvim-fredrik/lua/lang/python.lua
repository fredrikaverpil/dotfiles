local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      return executable_path
    end
  end
  return executable_name
end

local function find_debugpy_python_path()
  -- Return the path to the debugpy python executable if it is
  -- installed in $VIRTUAL_ENV, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/debugpy", true, true)
    if table.concat(paths, ", ") ~= "" then
      local path = vim.env.VIRTUAL_ENV .. "/bin/python"
      vim.notify("Using " .. path, vim.log.levels.INFO)
    end
  end
  local mason_registry = require("mason-registry")
  local path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
  vim.notify("Using " .. path, vim.log.levels.WARN)
  return path
end

return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      { "rcarriga/nvim-notify" },
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruff" })
        end,
      },
    },
    ft = { "python" },
    opts = function(_, opts)
      opts.formatters_by_ft.python = { "ruff_format" }
      local formatters = require("conform.formatters")
      local command = prefer_bin_from_venv("ruff")
      vim.notify("Using " .. command, vim.log.levels.INFO)
      formatters.ruff_format.command = command
    end,
  },

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      { "rcarriga/nvim-notify" },
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruff", "mypy" })
        end,
      },
    },
    ft = { "python" },
    opts = function(_, opts)
      opts.linters_by_ft["python"] = { "mypy" }
      local command = prefer_bin_from_venv("mypy")
      vim.notify("Using " .. command, vim.log.levels.INFO)
      opts.linters["mypy"] = {
        cmd = command,
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
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
    ft = { "python" },
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
    optional = true,
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
    dependencies = {
      { "rcarriga/nvim-notify" },
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
        ft = { "python" },
        config = function()
          local dap_python = require("dap-python")
          local dap_python_path = find_debugpy_python_path()
          dap_python.setup(dap_python_path)
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
