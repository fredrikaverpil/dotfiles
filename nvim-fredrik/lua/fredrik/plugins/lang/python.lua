local root_files = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
  "requirements.txt",
  "uv.lock",
  "setup.py",
  "setup.cfg",
  "Pipfile",
  "pyrightconfig.json",
  ".git",
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.py" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

return {
  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "mypy" })
        end,
      },
    },
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["python"] = { "mypy" }
      opts.linters["mypy"] = {
        cmd = function()
          local found_bin = vim.fn.system("which mypy")
          if found_bin ~= "" and string.find(found_bin, "mason") then
            vim.notify_once("mypy used from mason: " .. found_bin, vim.log.levels.WARN)
          end
          return "mypy"
        end,
      }
    end,
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
          {
            "mason-org/mason.nvim",
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

        ---@type vim.lsp.Config
        ruff = {
          -- lsp: https://docs.astral.sh/ruff/editors/setup/#neovim
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/ruff.lua
          cmd = { "ruff", "server" },
          filetypes = { "python" },
          -- root_dir = (function()
          --   return vim.fs.root(0, root_files)
          -- end)(),
          on_attach = function(client, bufnr)
            if client.name == "ruff" then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end,
          -- HACK: explicitly setting offset encoding:
          -- https://github.com/astral-sh/ruff/issues/14483#issuecomment-2526717736
          capabilities = {
            general = {
              -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
              positionEncodings = { "utf-16" },
            },
          },
          init_options = {
            settings = {
              -- https://docs.astral.sh/ruff/editors/settings/
              configurationPreference = "filesystemFirst",
              lineLength = 88,
            },
          },
          settings = {
            ruff = {},
          },
        },

        ---@type vim.lsp.Config
        basedpyright = {
          -- lsp: https://github.com/DetachHead/basedpyright
          --      https://docs.basedpyright.com/latest/configuration/language-server-settings/
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/basedpyright.lua
          cmd = { "basedpyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = root_files,
          log_level = vim.lsp.protocol.MessageType.Debug,
          settings = {
            python = {
              venvPath = os.getenv("VIRTUAL_ENV"),
              pythonPath = vim.fn.exepath("python"),
            },
            basedpyright = {
              -- https://docs.basedpyright.com/#/settings
              disableOrganizeImports = true, -- deletgate to ruff
              analysis = {
                -- NOTE: uncomment this to ignore linting. Good for projects where
                -- basedpyright lights up as a christmas tree.
                -- ignore = { "*" },
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
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
          "mason-org/mason.nvim",
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "debugpy" })
        end,
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function(_, opts)
          require("dap-python").setup("uv", opts)
        end,
      },
    },
  },
}
