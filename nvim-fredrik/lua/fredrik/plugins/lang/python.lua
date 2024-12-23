--- Find the path to the binary in the python virtual environment.
--- First search active virtual environment, then .venv folder,
--- then mason and last give up.
--- @param name string
--- @return string
local function find_python_binary(name)
  local path
  local cmd
  if vim.env.VIRTUAL_ENV ~= nil then
    path = vim.env.VIRTUAL_ENV
  else
    path = vim.fn.getcwd() .. "/.venv"
  end
  local results = vim.fs.find({ name }, { type = "file", path = path, limit = 1 })
  if #results == 1 then
    cmd = results[1]
    if vim.fn.filereadable(cmd) == 1 then
      return cmd
    end
  end

  if name == "python" or name == "python3" then
    -- cannot be found through mason-registry
    return name
  end

  local pkg = require("mason-registry").get_package(name)
  if pkg ~= nil then
    cmd = pkg:get_install_path() .. "/bin/" .. name
    if vim.fn.filereadable(cmd) == 1 then
      return cmd
    end
  end

  return name
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.py" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "88"
    vim.g.python3_host_prog = find_python_binary("python")
  end,
})

return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "python" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "isort", "ruff" })
        end,
      },
    },
    opts = function(_, opts)
      opts.formatters_by_ft.python = { "isort", "ruff_format" }
      opts.formatters["isort"] = {
        command = function()
          return find_python_binary("isort")
        end,
      }
      opts.formatters["ruff_format"] = {
        command = function()
          return find_python_binary("ruff")
        end,
      }
    end,
  },

  {
    "mfussenegger/nvim-lint",
    enabled = true,
    lazy = true,
    ft = { "python" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "mypy", "ruff" })
        end,
      },
    },
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["python"] = { "mypy", "ruff" }
      opts.linters["mypy"] = {
        cmd = function()
          return find_python_binary("ruff")
        end,
      }
      opts.linters["ruff"] = {
        cmd = function()
          return find_python_binary("ruff")
        end,
      }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
    -- ft = { "python" },
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
          vim.list_extend(opts.ensure_installed, { "basedpyright", "ruff" })
        end,
      },
    },
    opts = {
      servers = {
        basedpyright = {
          filetypes = { "python" },

          -- https://docs.basedpyright.com/#/settings
          settings = {
            basedpyright = {
              disableOrganizeImports = false, -- NOTE: use code action (ruff lsp)
              analysis = {
                -- NOTE: uncomment this to ignore linting. Good for projects where
                -- basedpyright lights up as a christmas tree.
                -- ignore = { "*" },
              },
            },
          },
        },

        ruff = {
          filetypes = { "python" },

          -- https://docs.astral.sh/ruff/editors/setup/#neovim
          enabled = false, -- NOTE: conform and nvim-lint are used instead
          on_attach = function(client, bufnr)
            if client.name == "ruff" then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end,
          init_options = {
            settings = {
              -- https://docs.astral.sh/ruff/editors/settings/
              configurationPreference = "filesystemFirst",
              lineLength = 88,
              lint = {
                enabled = false, -- NOTE: it does not work to disable this.
              },
              -- NOTE: to temporarily stop formatting, use ":LspStop ruff"
            },
          },
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "python" },
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-python"] = {
        runner = "pytest",
        -- TODO: write coverage...
        args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
        dap = { justMyCode = false },
      }
    end,
  },

  {
    "andythigpen/nvim-coverage",
    lazy = true,
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
    lazy = true,
    ft = { "python" },
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "debugpy" })
        end,
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          local dap_python = require("dap-python")
          local debugpy_path = find_python_binary("python3")
          dap_python.setup(debugpy_path)
        end,
      },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    lazy = true,
    event = "VeryLazy",
    ft = { "python" },
    branch = "regexp", -- https://github.com/linux-cultist/venv-selector.nvim/tree/regexp
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    opts = {
      notify_user_on_venv_activation = true,
    },
    keys = require("fredrik.config.keymaps").setup_venv_selector_keymaps(),
  },
}
