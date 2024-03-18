local function prefer_bin_from_venv(executable_name)
  -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
  local notifications = require("utils.defaults").notifications.python

  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
    local venv_path = table.concat(paths, ", ")
    if venv_path ~= "" and venv_path ~= nil then
      notifications[executable_name].path = venv_path
      return venv_path
    end
  end

  local mason_registry = require("mason-registry")
  local mason_path = mason_registry.get_package(executable_name):get_install_path() .. "/bin/" .. executable_name
  if mason_path then
    notifications[executable_name].path = mason_path
    notifications[executable_name].warn = true
    return mason_path
  end

  local global_path = vim.fn.exepath(executable_name)
  if global_path then
    notifications[executable_name].path = global_path
    notifications[global_path].warn = true
    return global_path
  end

  return nil
end

local function find_debugpy_python_path()
  -- Return the path to the debugpy python executable if it is
  -- installed in $VIRTUAL_ENV, otherwise get it from Mason
  local notifications = require("utils.defaults").notifications.python

  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/debugpy", true, true)
    if table.concat(paths, ", ") ~= "" then
      local venv_path = vim.env.VIRTUAL_ENV .. "/bin/python"
      notifications.debugpy.path = venv_path
      return venv_path
    end
  end

  local mason_registry = require("mason-registry")
  local mason_path = mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python"
  if mason_path then
    notifications.debugpy.path = mason_path
    notifications.debugpy.warn = true
    return mason_path
  end

  return nil
end

local function find_python_executable()
  local notifications = require("utils.defaults").notifications.python

  if vim.env.VIRTUAL_ENV then
    local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/python", true, true)
    local executable_path = table.concat(paths, ", ")
    if executable_path ~= "" then
      notifications.python3.path = executable_path
      return executable_path
    end
  elseif vim.fn.filereadable(".venv/bin/python") == 1 then
    local executable_path = vim.fn.expand(".venv/bin/python")
    notifications.python3.path = executable_path
    return executable_path
  else
    local global_path = vim.fn.exepath("python3")
    if global_path then
      notifications.python3.path = global_path
      notifications.python3.warn = true
      return global_path
    end
  end

  return nil
end

local function notify_tooling(lang)
  local notifications = require("utils.defaults").notifications[lang]
  local infos = ""
  local warnings = ""
  local errors = ""
  for tool, info in pairs(notifications) do
    if type(info) == "table" then
      if info.path ~= nil then
        if info.warn == true then
          warnings = warnings .. "Using " .. tool .. " from Mason (" .. info.path .. "), consider installing it in your virtual environment.\n"
        else
          infos = infos .. "Using " .. tool .. ": " .. info.path .. "\n"
        end
      else
        errors = errors .. tool .. " not found.\n"
      end
    end
  end

  -- remove newline from end of strings
  infos = string.sub(infos, 1, -2)
  warnings = string.sub(warnings, 1, -2)
  errors = string.sub(errors, 1, -2)

  if infos ~= "" then
    vim.notify_once(infos, vim.log.levels.INFO)
  end
  if warnings ~= "" then
    vim.notify_once(warnings, vim.log.levels.WARN)
  end
  if errors ~= "" then
    vim.notify_once(errors, vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.py" },
  callback = function()
    local notifications = require("utils.defaults").notifications.python

    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "88"
    if not vim.g.python3_host_prog then
      notifications.python3.path = find_python_executable()
      vim.g.python3_host_prog = notifications.python3.path
    end

    if not notifications._emitted then
      notify_tooling("python")
      notifications._emitted = true
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
