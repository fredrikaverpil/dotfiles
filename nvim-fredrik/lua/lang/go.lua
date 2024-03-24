local function find_file(filename, excluded_dirs)
  if not excluded_dirs then
    excluded_dirs = { ".git", "node_modules", ".venv" }
  end
  local exclude_str = ""
  for _, dir in ipairs(excluded_dirs) do
    exclude_str = exclude_str .. " --exclude " .. dir
  end
  local command = "fd --hidden --no-ignore" .. exclude_str .. " '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  --  local command = "fd --hidden --no-ignore '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  local file = io.popen(command):read("*l")
  local path = file and file or nil

  if path ~= nil then
    require("utils.defaults").notifications.go[filename].path = path
  end

  return path
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl", "proto" },
  callback = function()
    -- set go specific options
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "120"

    -- show notification if golangci-lint config is found
    local notifications = require("utils.defaults").notifications.go
    if notifications[".golangci.yml"].path and not notifications._emitted then
      vim.notify_once("Using golangci-lint config: " .. notifications[".golangci.yml"].path, vim.log.levels.INFO)
      notifications._emitted = true
    end
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

  -- {
  --   "mfussenegger/nvim-lint",
  --   enabled = false,
  --   dependencies = {
  --     {
  --       "williamboman/mason.nvim",
  --       opts = function(_, opts)
  --         opts.ensure_installed = opts.ensure_installed or {}
  --         vim.list_extend(opts.ensure_installed, { "golangci-lint" })
  --       end,
  --     },
  --   },
  --   ft = { "go", "gomod", "gowork", "gotmpl" },
  --   opts = function(_, opts)
  --     local args = require("lint").linters.golangcilint.args -- defaults
  --     local config_file = find_file(".golangci.yml")
  --     if config_file ~= nil then
  --       require("utils.defaults").golangcilint_config_path = config_file
  --       args = {
  --         "run",
  --         "--out-format",
  --         "json",
  --         "--config",
  --         config_file,
  --         function()
  --           return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  --         end,
  --       }
  --     end
  --
  --     opts.linters_by_ft["go"] = { "golangcilint" }
  --     opts.linters["golangcilint"] = { args = args }
  --   end,
  -- },

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
            enabled = true,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "gopls", "golangci_lint_ls" })
        end,
      },
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    opts = function(_, opts)
      local function golangcilint_setup()
        local lspconfig = require("lspconfig")
        local golangcilint_command = { "golangci-lint", "run", "--enable-all", "--out-format", "json", "--issues-exit-code=1" }
        local config_file = find_file(".golangci.yml")
        if config_file then
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
            on_attach = function(client, bufnr)
              require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
            end,
          },
        }
      end

      opts.servers = {

        golangci_lint_ls = golangcilint_setup(),

        gopls = {
          -- for all options, see:
          -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
          -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
          -- for more details, also see:
          -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
          -- https://github.com/golang/tools/blob/master/gopls/README.md

          on_attach = function(client, bufnr)
            require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
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
      -- NOTE: usinga personal fork with bugfixes, would be nicer to use original plugin...
      -- "nvim-neotest/neotest-go",
      "fredrikaverpil/neotest-go-fork",
      branch = "main",
    },
    opts = function(_, opts)
      -- TODO: potentially use this function to mitigate always running all tests.
      -- see; https://github.com/nvim-neotest/neotest-go/pull/81
      local function get_nearest_function_name()
        local ts_utils = require("nvim-treesitter.ts_utils")
        local node = ts_utils.get_node_at_cursor()

        while node do
          if node:type() == "function_declaration" then
            return ts_utils.get_node_text(node:child(1))[1]
          end
          node = node:parent()
        end
      end

      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-go"] = {
        experimental = {
          test_table = true,
        },
        args = { "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out" },
        -- TODO: figure out if this should be enabled: recursive_run = true,
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
        config = function()
          require("dap-go").setup({})
        end,
      },
    },
  },
}
