-- https://www.lazyvim.org/plugins/lsp
-- NOTE: don't forget to update treesitter for languages
-- NOTE: see lazy.lua for extras that configure LSPs, formatters, linters and code actions.

local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      print("Using path for " .. executable_name .. ": " .. executable_path, vim.log.levels.INFO)
      return executable_path
    end
  end

  -- NOTE: this can probably be removed, as mason is puttiing stuff on $PATH for us:
  -- local mason_registry = require("mason-registry")
  -- local mason_path = mason_registry.get_package(executable_name):get_install_path() .. "/venv/bin/" .. executable_name
  -- print("Using path for " .. executable_name .. ": " .. mason_path, vim.log.levels.WARN)
  -- return mason_path

  return executable_name
end

return {

  {
    "stevearc/conform.nvim",
    dependencies = {
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
      formatters.ruff_format.command = prefer_bin_from_venv("ruff")
    end,
  },

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruff", "mypy" })
        end,
      },
    },
    ft = { "python" },
    opts = {
      linters_by_ft = {
        python = { "mypy" },
      },
      linters = {
        mypy = {
          cmd = prefer_bin_from_venv("mypy"),
        },
      },
    },
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

          print("Using path for dap-python: " .. dap_python_path)

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
