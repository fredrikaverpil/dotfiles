vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    -- set go specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"
  end,
})

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
    ft = { "go", "gomod", "gowork", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
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
          -- main readme: https://github.com/golang/tools/blob/master/gopls/doc/features/README.md
          --
          -- for all options, see:
          -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
          -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
          -- for more details, also see:
          -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
          -- https://github.com/golang/tools/blob/master/gopls/README.md

          settings = {

            -- NOTE: this is not an explicit list. The gopls defaults will apply if not overridden here.
            gopls = {
              analyses = {
                -- https://github.com/golang/tools/blob/master/gopls/internal/settings/analysis.go
                -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md

                -- the traditional vet suite
                appends = true,
                asmdecl = true,
                assign = true,
                atomic = true,
                bools = true,
                buildtag = true,
                cgocall = true,
                composite = true,
                copylock = true,
                defers = true,
                deprecated = true,
                directive = true,
                errorsas = true,
                framepointer = true,
                httpresponse = true,
                ifaceassert = true,
                loopclosure = true,
                lostcancel = true,
                nilfunc = true,
                printf = true,
                shift = true,
                sigchanyzer = true,
                slog = true,
                stdmethods = true,
                stdversion = true,
                stringintconv = true,
                structtag = true,
                testinggoroutine = true,
                tests = true,
                timeformat = true,
                unmarshal = true,
                unreachable = true,
                unsafeptr = true,
                unusedresult = true,

                -- not suitable for vet:
                -- - some (nilness) use go/ssa; see #59714.
                -- - others don't meet the "frequency" criterion;
                --   see GOROOT/src/cmd/vet/README.
                atomicalign = true,
                deepequalerrors = true,
                nilness = true,
                sortslice = true,
                embeddirective = true,

                -- disabled due to high false positives
                shadow = false,
                useany = false,
                -- fieldalignment = false, -- annoying and also  NOTE: deprecated in gopls v0.17.0

                -- "simplifiers": analyzers that offer mere style fixes
                -- gofmt -s suite:
                simplifycompositelit = true,
                simplifyrange = true,
                simplifyslice = true,
                -- other simplifiers:
                infertypeargs = true,
                unusedparams = true,
                unusedwrite = true,

                -- type-error analyzers
                -- These analyzers enrich go/types errors with suggested fixes.
                fillreturns = true,
                nonewvars = true,
                noresultvalues = true,
                stubmethods = true,
                undeclaredname = true,
                unusedvariable = true,
              },
              codelenses = {
                -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
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
                -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              -- completion options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              usePlaceholders = true,
              completeUnimported = true,
              experimentalPostfixCompletions = true,
              completeFunctionCalls = true,
              -- build options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              directoryFilters = { "-**/node_modules", "-**/.git", "-.vscode", "-.idea", "-.vscode-test" },
              -- formatting options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              gofumpt = false, -- handled by conform instead.
              -- ui options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              semanticTokens = false, -- disabling this enables treesitter injections (for sql, json etc)
              -- diagnostic options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              staticcheck = true,
              vulncheck = "imports",
              analysisProgressReporting = true,
            },
          },
        },
      }
    end,
  },

  {
    "maxandron/goplements.nvim",
    ft = "go",
    opts = {},
  },

  {
    "ray-x/go.nvim",
    enabled = true,
    ft = { "go", "gomod" },
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        lsp_cfg = false, -- handled with nvim-lspconfig instead
        lsp_inlay_hints = {
          enable = false, -- handled with LSP keymap toggle instead
        },
        dap_debug = false, -- handled by nvim-dap instead
        luasnip = true,
      })
    end,
    event = { "CmdlineEnter" },
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
        go_test_args = {
          "-v",
          "-count=1",
          "-race",
          "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
          -- "-p=1",
          "-parallel=1",
        },

        -- experimental
        dev_notifications = true,
        runner = "gotestsum",
        gotestsum_args = { "--format=standard-verbose" },
        -- testify_enabled = true,
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
        opts = {
          dap_configurations = {
            {
              type = "go",
              name = "Debug opened file's cmd/cli",
              request = "launch",
              cwd = "${fileDirname}", -- FIXME:  should work from  repo root
              program = "./${relativeFileDirname}",
              args = {},
            },
          },
        },
        config = function(_, opts)
          require("dap-go").setup(opts)
        end,
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

  {
    -- TODO: try to configure this so the virtual text is helpful.
    "theHamsta/nvim-dap-virtual-text",
    enabled = false,
  },
}
