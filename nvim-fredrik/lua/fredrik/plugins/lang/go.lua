vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork" },
  callback = function()
    -- set go specific options
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.expandtab = false

    vim.opt_local.colorcolumn = "120"
  end,
})

local golangci_config_file = nil
local tags = "-tags=wireinject,integration"

local function golangcilint_args()
  local args = {}
  args = {
    "run",
    "--out-format",
    "json",
    "--issues-exit-code=0",
    "--show-stats=false",
    "--print-issued-lines=false",
    "--print-linter-name=false",

    -- config file
    function()
      if golangci_config_file ~= nil then
        return golangci_config_file
      end
      local found
      found = vim.fs.find({ ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" }, { type = "file", limit = 1 })
      if #found == 1 then
        local filepath = found[1]
        golangci_config_file = filepath
        return "--config", golangci_config_file
      else
        local filepath = require("fredrik.utils.environ").getenv("DOTFILES") .. "/templates/.golangci.yml"
        golangci_config_file = filepath
        return "--config", golangci_config_file
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
      ensure_installed = { "go", "gomod", "gosum", "gowork" },
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
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["go"] = { "golangcilint" }
      opts.linters["golangcilint"] = {
        args = golangcilint_args(),
        ignore_exitcode = true, -- NOTE: https://github.com/mfussenegger/nvim-lint/commit/3d5190d318e802de3a503b74844aa87c2cd97ef0
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
            opts = function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
            end,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gopls" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        gopls = {
          -- lsp: https://github.com/golang/tools/blob/master/gopls
          -- reference: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/gopls.lua
          --
          -- main readme: https://github.com/golang/tools/blob/master/gopls/doc/features/README.md
          --
          -- for all options, see:
          -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
          -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
          -- for more details, also see:
          -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
          -- https://github.com/golang/tools/blob/master/gopls/README.md
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gosum" },
          root_markers = { "go.work", "go.mod", ".git" },
          settings = {
            gopls = {
              buildFlags = { tags },
              -- env = {},
              -- analyses = {
              --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/analysis.go
              --   -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
              -- },
              -- codelenses = {
              --   -- https://github.com/golang/tools/blob/master/gopls/doc/codelenses.md
              --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              -- },
              hints = {
                -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
                -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go

                parameterNames = true,
                assignVariableTypes = true,
                constantValues = true,
                compositeLiteralTypes = true,
                compositeLiteralFields = true,
                functionTypeParameters = true,
              },
              -- completion options
              -- https://github.com/golang/tools/blob/master/gopls/doc/features/completion.md
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go

              -- build options
              -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
              -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#build
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
      },
    },
    opts_extend = {
      "servers.gopls.filetypes",
      "servers.gopls.settings.gopls.templateExtensions",
    },
  },

  {
    "maxandron/goplements.nvim",
    lazy = true,
    ft = "go",
    opts = {},
  },

  {
    "ray-x/go.nvim",
    lazy = true,
    ft = { "go", "gomod" },
    enabled = false,
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
    lazy = true,
    ft = { "go" },
    dependencies = {
      {
        "fredrikaverpil/neotest-golang",
        -- dependencies = {
        --   "uga-rosa/utf8.nvim",
        -- },
        dir = "~/code/public/neotest-golang",
      },
    },

    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-golang"] = {
        go_list_args = { tags },
        go_test_args = {
          "-v",
          "-count=1",
          "-race",
          "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
          -- "-p=1",
          "-parallel=1",
          tags,
        },
        runner = "gotestsum",
        gotestsum_args = { "--format=standard-verbose" },
        -- sanitize_output = true,
        -- log_level = vim.log.levels.TRACE,

        -- experimental
        dev_notifications = true,
      }
    end,
  },

  {
    "andythigpen/nvim-coverage",
    lazy = true,
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
    lazy = true,
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
        "theHamsta/nvim-dap-virtual-text",
      },
      {
        "leoluz/nvim-dap-go",
        opts = {
          dap_configurations = {
            {
              type = "go",
              name = "Delve: debug opened file's cmd/cli",
              request = "launch",
              cwd = "${fileDirname}", -- FIXME: should work from repo root
              program = "./${relativeFileDirname}",
              args = {},
            },
            {
              type = "go",
              name = "Delve: debug test (manually enter test name)",
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
        config = function(_, opts)
          require("dap-go").setup(opts)
        end,
      },
    },
    opts = {
      -- configurations = {
      --   go = {},
      -- },
    },
  },

  {
    "CRAG666/code_runner.nvim",
    lazy = true,
    opts = {
      filetype = {
        go = {
          "go run",
        },
      },
    },
  },
}
