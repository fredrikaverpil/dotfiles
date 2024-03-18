local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  local notifications = require("utils.defaults").notifications
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" and executable_path ~= nil then
      notifications[executable_name].path = executable_path
      return executable_path
    end
  end

  -- vim.notify("Could not find " .. executable_name .. " in virtual environment.", vim.log.levels.WARN)
  notifications[executable_name].warn = true
  return executable_name
end

local function find_debugpy_python_path()
  -- Return the path to the debugpy python executable if it is
  -- installed in $VIRTUAL_ENV, otherwise get it from Mason

  local notifications = require("utils.defaults").notifications

  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/debugpy", true, true)
    if table.concat(paths, ", ") ~= "" then
      local executable_path = vim.env.VIRTUAL_ENV .. "/bin/python"
      -- vim.notify("Using " .. executable_path)
      notifications.debugpy.path = executable_path
    end
  end
  local mason_registry = require("mason-registry")
  local path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
  notifications.debugpy.path = path
  notifications.debugpy.warn = true
  return path
end

local function find_python_executable()
  local notifications = require("utils.defaults").notifications
  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/python", true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      notifications.python.path = executable_path
      return executable_path
    end
  elseif vim.fn.filereadable(".venv/bin/python") == 1 then
    local executable_path = vim.fn.expand(".venv/bin/python")
    notifications.python.path = executable_path
    return executable_path
  end
  notifications.python.warn = true
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function()
    local notifications = require("utils.defaults").notifications

    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "88"
    if not vim.g.python3_host_prog then
      notifications.python.path = find_python_executable()
      vim.g.python3_host_prog = notifications.python.path
    end

    -- show notifications around tooling
    if notifications.ruff.path and not notifications.ruff.notified then
      if notifications.ruff.warn then
        vim.notify("Using ruff from Mason, consider installing it in your virtual environment.", vim.log.levels.WARN)
      else
        vim.notify("Using ruff config: " .. notifications.ruff.path, vim.log.levels.INFO)
      end
      notifications.ruff.notified = true
    end
    if notifications.mypy.path and not notifications.mypy.notified then
      if notifications.mypy.warn then
        vim.notify("Using mypy from Mason, consider installing it in your virtual environment.", vim.log.levels.WARN)
      else
        vim.notify("Using mypy config: " .. notifications.mypy.path, vim.log.levels.INFO)
      end
      notifications.mypy.notified = true
    end
    if notifications.debugpy.path and not notifications.debugpy.notified then
      if notifications.debugpy.warn then
        vim.notify("Using debugpy from Mason, consider installing it in your virtual environment.", vim.log.levels.WARN)
      else
        vim.notify("Using debugpy config: " .. notifications.debugpy.path, vim.log.levels.INFO)
      end
      notifications.debugpy.notified = true
    end
    if notifications.python.path and not notifications.python.notified then
      if notifications.python.warn then
        vim.notify("Could not use Python from virtual environment, using: " .. vim.g.python3_host_prog, vim.log.levels.WARN)
      else
        vim.notify("Using python: " .. vim.g.python3_host_prog, vim.log.levels.INFO)
      end
      notifications.python.notified = true
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
      local formatters = require("conform.formatters")
      local ruff_path = prefer_bin_from_venv("ruff")
      opts.formatters_by_ft.python = { "ruff_format" }
      if ruff_path then
        formatters.ruff_format.command = ruff_path
      end
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
          vim.list_extend(opts.ensure_installed, { "mypy" })
        end,
      },
    },
    opts = function(_, opts)
      local mypy_path = prefer_bin_from_venv("mypy")
      opts.linters_by_ft["python"] = { "mypy" }
      if mypy_path then
        opts.linters["mypy"] = {
          cmd = prefer_bin_from_venv("mypy"),
        }
      end
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
          local debugpy_path = find_debugpy_python_path()
          dap_python.setup(debugpy_path)
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
