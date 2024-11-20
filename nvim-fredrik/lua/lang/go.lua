vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    -- set go specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"
  end,
})

G_golangci_config_file = nil

local function golangcilint_args()
  local args = {}
  args = {
    "run",
    "--out-format",
    "json",

    -- config file
    function()
      if G_golangci_config_file ~= nil then
        return G_golangci_config_file
      end
      local found
      found = vim.fs.find({ ".golangci.yml" }, { type = "file", limit = 1 })
      if #found == 1 then
        local cmd = found[1]
        G_golangci_config_file = found[1]
        return "--config", cmd
      else
        local template = vim.fn.expand("$DOTFILES/template/.golangci.yml")
        return "--config", template
      end
    end,

    -- filename
    function()
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
    end,
  }

  return args
end

return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "go", "gomod", "gosum", "gotmpl", "gowork" },
    },
  },

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
        go = { "goimports", "gci", "gofumpt", "golines" },
      },
      formatters = {
        goimports = {
          -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/goimports.lua
          args = { "-srcdir", "$FILENAME" },
        },
        gci = {
          -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/gci.lua
          args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
        },
        gofumpt = {
          -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/gofumpt.lua
          prepend_args = { "-extra", "-w", "$FILENAME" },
          stdin = false,
        },
        golines = {
          -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/golines.lua
          -- NOTE: golines will use goimports as base formatter by default which can be slow.
          -- see https://github.com/segmentio/golines/issues/33
          prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
        },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    enabled = true, -- FIXME: use lsp for golangci-lint instead when possible?
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "golangci-lint" })
        end,
      },
    },
    opts = function(_, opts)
      opts.linters_by_ft["go"] = { "golangcilint" }
      opts.linters["golangcilint"] = { args = golangcilint_args() }
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
            opts = function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
              -- FIXME: https://github.com/nametake/golangci-lint-langserver/issues/33
              -- vim.list_extend(opts.ensure_installed, { "golangci-lint", "golangci-lint-langserver" })
            end,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {
            "gopls",
            -- "golangci_lint_ls", -- FIXME: https://github.com/nametake/golangci-lint-langserver/issues/33
          })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
    opts = function(_, opts)
      local function golangcilint_cmd()
        return table.insert(golangcilint_args(), 0, "golangci-lint")
      end

      opts.servers = {

        -- FIXME: https://github.com/nametake/golangci-lint-langserver/issues/33
        -- golangci_lint_ls = {
        --   -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/golangci_lint_ls.lua
        --   -- https://github.com/nametake/golangci-lint-langserver
        --   cmd = { "golangci-lint-langserver" },
        --   filetypes = { "go", "gomod" },
        --   init_options = {
        --     command = function()
        --       return golangcilint_cmd()
        --     end,
        --   },
        -- },

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
              -- analyses = {
              --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/analysis.go
              --   -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
              -- },
              -- codelenses = {
              --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              -- },
              -- hints = {
              --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              -- },
              -- completion options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go

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

  -- {
  --   "hrsh7th/nvim-cmp",
  --   dependencies = {
  --     "Snikimonkd/cmp-go-pkgs",
  --     enabled = true, -- NOTE: not using nvim-cmp anymore.
  --   },
  --   ft = { "go", "gomod" },
  --   opts = function(_, opts)
  --     opts.sources = opts.sources or {}
  --     table.insert(opts.sources, { name = "go_pkgs" })
  --   end,
  -- },

  {
    "ray-x/go.nvim",
    enabled = false,
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
