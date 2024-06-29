vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    -- set go specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"
  end,
})

--- Control whether to enable workspace diagnostics.
--- This can slow down gopls in ginormous projects.
local workspace_diagnostics_enabled = true

return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gofumpt", "goimports", "gci", "golines" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports", "gci", "golines" },
      },
      formatters = {
        gofumpt = {
          prepend_args = { "-extra" },
        },
        gci = {
          args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
        },
        goimports = {
          args = { "-srcdir", "$FILENAME" },
        },
        golines = {
          -- golines will use goimports as base formatter by default which is slow.
          -- see https://github.com/segmentio/golines/issues/33
          prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
        },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    enabled = true, -- FIXME: use lsp when possible: https://github.com/nametake/golangci-lint-langserver/issues/33
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "golangci-lint" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = function(_, opts)
      local args = require("lint").linters.golangcilint.args -- defaults
      local config_file = require("utils.find").find_file(".golangci.yml")
      if config_file then
        vim.notify_once("Found file: " .. config_file, vim.log.levels.INFO)
        require("utils.defaults").golangcilint_config_path = config_file
        args = {
          "run",
          "--out-format",
          "json",
          "--config",
          config_file,
          function()
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
          end,
        }
      end

      opts.linters_by_ft["go"] = { "golangcilint" }
      opts.linters["golangcilint"] = { args = args }
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
          {
            "artemave/workspace-diagnostics.nvim",
            enabled = workspace_diagnostics_enabled,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "gopls",

            -- FIXME: https://github.com/nametake/golangci-lint-langserver/issues/33
            -- "golangci_lint_ls"
          })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = function(_, opts)
      local function golangcilint_setup()
        local lspconfig = require("lspconfig")
        local golangcilint_command = { "golangci-lint", "run", "--enable-all", "--out-format", "json", "--issues-exit-code=1" }
        local config_file = require("utils.find").find_file(".golangci.yml")
        if config_file then
          vim.notify_once("Found file: " .. config_file, vim.log.levels.INFO)
          golangcilint_command = { "golangci-lint", "run", "--out-format", "json", "--config", config_file, "--issues-exit-code=1" }
        end

        return {
          golangci_lint_ls = {
            -- https://github.com/nametake/golangci-lint-langserver
            cmd = { "golangci-lint-langserver" },
            filetypes = { "go", "gomod" },
            root_dir = lspconfig.util.root_pattern("go.mod"),
            init_options = {
              command = golangcilint_command,
            },
          },
        }
      end

      opts.servers = {

        -- FIXME: https://github.com/nametake/golangci-lint-langserver/issues/33
        -- golangci_lint_ls = golangcilint_setup(),

        gopls = {
          -- for all options, see:
          -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
          -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
          -- for more details, also see:
          -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
          -- https://github.com/golang/tools/blob/master/gopls/README.md

          on_attach = function(client, bufnr)
            if workspace_diagnostics_enabled then
              require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
            end
          end,

          settings = {

            gopls = {
              analyses = {
                fieldalignment = false, -- annoying
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              completeUnimported = true,
              directoryFilters = { "-**/node_modules", "-**/.git", "-.vscode", "-.idea", "-.vscode-test" },
              gofumpt = true,
              semanticTokens = true,
              staticcheck = true,
              usePlaceholders = true,
            },
          },
        },
      }
    end,
  },

  {
    "nvim-neotest/neotest",
    ft = { "go" },
    dependencies = {
      {
        "fredrikaverpil/neotest-golang",
        dir = "~/code/public/neotest-golang",
      },
    },

    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-golang"] = {
        dev_notifications = true,
        go_test_args = {
          "-v",
          "-count=1",
          "-race",
          -- "-p=1",
          "-parallel=1",
          "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
        },
        dap_go_enabled = true,
      }
    end,
  },

  {
    "andythigpen/nvim-coverage",
    ft = { "go" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- https://github.com/andythigpen/nvim-coverage/blob/main/doc/nvim-coverage.txt
      auto_reload = true,
      lang = {
        go = {
          coverage_file = vim.fn.getcwd() .. "/coverage.out",
        },
      },
    },
  },

  {
    "mfussenegger/nvim-dap",
    ft = { "go" },
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
        },
        opts = {
          ensure_installed = { "delve" },
        },
      },
      {
        "leoluz/nvim-dap-go",
        opts = {},
      },
    },
    opts = {
      configurations = {
        go = {
          -- See require("dap-go") source for full dlv setup.
          {
            type = "go",
            name = "Debug test (manually enter test name)",
            request = "launch",
            mode = "test",
            program = "./${relativeFileDirname}",
            args = function()
              local testname = vim.fn.input("Test name (^regexp$ ok): ")
              return { "-test.run", testname }
            end,
          },
        },
      },
    },
  },
}
