vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = false

    vim.opt_local.colorcolumn = "120"
  end,
})

local golangci_config_filepath_cache = nil
local tags = "-tags=wireinject,integration"

local function golangci_config()
  if golangci_config_filepath_cache ~= nil then
    vim.notify_once("golangci-lint: " .. golangci_config_filepath_cache, vim.log.levels.INFO)
    return "--config=" .. golangci_config_filepath_cache
  end

  local found_bin = vim.fn.system("which golangci-lint")
  if not string.find(found_bin, "mason/bin") then
    vim.notify("golangci-lint binary not provided by mason: " .. found_bin, vim.log.levels.WARN)
  end

  local found_config
  found_config = vim.fs.find(
    { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" },
    { type = "file", limit = 1 }
  )
  if #found_config == 1 then
    local filepath = found_config[1]
    golangci_config_filepath_cache = filepath
    local arg = "--config=" .. golangci_config_filepath_cache
    return arg
  else
    local filepath = require("fredrik.utils.environ").getenv("DOTFILES") .. "/templates/.golangci.yml"
    golangci_config_filepath_cache = filepath
    local arg = "--config=" .. golangci_config_filepath_cache
    return arg
  end
end

local function golangci_filename()
  local filepath = vim.api.nvim_buf_get_name(0)
  local parent = vim.fn.fnamemodify(filepath, ":h")
  return parent
end

local function golangcilint_args()
  local ok, output = pcall(vim.fn.system, { "golangci-lint", "version" })
  if not ok then
    return
  end

  -- The golangci-lint install script and prebuilt binaries strip the v from the version
  --   tag so both strings must be checked
  if string.find(output, "version v1") or string.find(output, "version 1") then
    return {
      "run",
      "--out-format",
      "json",
      "--issues-exit-code=0",
      "--show-stats=false",
      "--print-issued-lines=false",
      "--print-linter-name=false",

      golangci_config,
      golangci_filename,
    }
  end

  return {
    "run",
    "--output.json.path=stdout",

    -- Overwrite values possibly set in .golangci.yml
    "--output.text.path=",
    "--output.tab.path=",
    "--output.html.path=",
    "--output.checkstyle.path=",
    "--output.code-climate.path=",
    "--output.junit-xml.path=",
    "--output.teamcity.path=",
    "--output.sarif.path=",

    "--issues-exit-code=0",
    "--show-stats=false",

    golangci_config,
    golangci_filename,
  }
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

        -- For debugging; to see the same output as the parser sees
        -- Important: make sure you don't have another golangci-lint biniary on $PATH
        -- parser = function(output, bufnr, cwd)
        --   vim.notify(vim.inspect(output))
        -- end,
      }
    end,
  },

  {
    "virtual-lsp-config",
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
    "fang2hou/go-impl.nvim",
    ft = "go",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    opts = {},
    cmd = { "GoImplOpen" },
  },

  {
    "zgs225/gomodifytags.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gomodifytags" })
        end,
      },
    },
    config = function(_, opts)
      require("gomodifytags").setup(opts) -- Optional: You can add any specific configuration here if needed.
    end,
    cmd = { "GoAddTags", "GoRemoveTags", "GoInstallModifyTagsBin" },
  },

  {
    "ray-x/go.nvim",
    lazy = true,
    ft = { "go", "gomod" },
    enabled = false,
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "virtual-lsp-config",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        remap_commands = { GoDoc = false }, -- NOTE: clashes with godoc.nvim
        lsp_cfg = false, -- handled with nvim-lspconfig instead
        lsp_inlay_hints = {
          enable = false, -- handled with LSP keymap toggle instead
        },
        dap_debug = false, -- handled by nvim-dap instead
        luasnip = false,
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
        dev = true, -- see lazy.lua for local path details
        -- dependencies = {
        --   "uga-rosa/utf8.nvim",
        -- },
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
        -- testify_enabled = true,
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
    "fredrikaverpil/godoc.nvim",
    dev = true, -- see lazy.lua for local path details
    dependencies = {
      { "folke/snacks.nvim" },
      {
        "nvim-treesitter/nvim-treesitter",
        opts = {
          ensure_installed = { "go" },
        },
      },
    },
    build = "go install github.com/lotusirous/gostdsym/stdsym@latest",
    opts = {
      adapters = {
        {
          name = "go",
          opts = {
            command = "GoDoc",
            get_syntax_info = function()
              return {
                filetype = "godoc", -- filetype for the buffer
                language = "markdown", -- tree-sitter parser, for syntax highlighting
              }
            end,
          },
        },
      },
      window = { type = "vsplit" },
      picker = { type = "snacks" },
    },
    -- cmd = { "GoDoc", "RustDoc" },
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
    "saghen/blink.cmp",
    dependencies = {
      "edte/blink-go-import.nvim",
      ft = "go",
      config = function()
        require("blink-go-import").setup()
      end,
    },
    opts = {
      sources = {
        default = {
          "go_pkgs",
        },
        providers = {
          go_pkgs = {
            module = "blink-go-import",
            name = "Import",
          },
        },
      },
    },
    opts_extend = {
      "sources.default",
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
