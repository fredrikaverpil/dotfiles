-- fork of https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/go.lua

local function find_file(filename)
  local command = "fd --hidden --no-ignore '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  local file = io.popen(command):read("*l")
  return file and file or nil
end

local use_golangci_config_if_available = function(linters)
  local config_file = find_file(".golangci.yml")
  if config_file then
    print("Using golangci-lint config: " .. config_file)
    return {
      "run",
      "--out-format",
      "json",
      "--config",
      config_file,
      function()
        return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
      end,
    }
  else
    return linters.golangcilint.args
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    ft = { "go" },
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "go",
        "gomod",
        "gowork",
        "gosum",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    ft = { "go" },
    dependencies = {
      "artemave/workspace-diagnostics.nvim",
    },
    opts = {
      inlay_hints = {
        enabled = false,
      },
      servers = {
        gopls = {
          keys = {
            -- Workaround for the lack of a DAP strategy in neotest-go: https://github.com/nvim-neotest/neotest-go/issues/12
            { "<leader>td", "<cmd>lua require('dap-go').debug_test()<CR>", desc = "Debug Nearest (Go)" },
          },
          settings = {
            -- https://github.com/golang/tools/blob/master/gopls/README.md
            -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
            -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
            -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
            gopls = {
              gofumpt = true,
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
              analyses = {
                fieldalignment = true, -- annoying
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              usePlaceholders = true,
              completeUnimported = true,
              staticcheck = true,
              directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
              semanticTokens = true,
            },
          },
        },
      },
      setup = {
        gopls = function(_, opts)
          -- workaround for gopls not supporting semanticTokensProvider
          -- https://github.com/golang/go/issues/54531#issuecomment-1464982242
          require("lazyvim.util").lsp.on_attach(function(client, bufnr)
            if client.name == "gopls" then
              require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
              if not client.server_capabilities.semanticTokensProvider then
                local semantic = client.config.capabilities.textDocument.semanticTokens
                client.server_capabilities.semanticTokensProvider = {
                  full = true,
                  legend = {
                    tokenTypes = semantic.tokenTypes,
                    tokenModifiers = semantic.tokenModifiers,
                  },
                  range = true,
                }
              end
            end
          end)
          -- end workaround
        end,
      },
    },
  },
  -- Ensure Go tools are installed
  {
    "williamboman/mason.nvim",
    ft = { "go" },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "goimports", "gofumpt", "gci", "golangci-lint" })
    end,
  },
  {
    "stevearc/conform.nvim",
    ft = { "go" },
    optional = true,
    opts = function(_, opts)
      local formatters = require("conform.formatters")
      formatters.golines.args = { "-m", "120" }
      formatters.gci.args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" }
      formatters.gofumpt.args = { "-extra" }
      local remove_from_formatters = {}
      local extend_formatters_with = {}
      local replace_formatters_with = {
        go = { "gofumpt", "goimports", "gci", "golines" }, -- FIXME: add golines in when possible
      }

      -- NOTE: conform.nvim can use a sub-list to run only the first available formatter (see docs)

      -- remove from opts.formatters_by_ft
      for ft, formatters_ in pairs(remove_from_formatters) do
        opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
          return not vim.tbl_contains(formatters_, formatter)
        end, opts.formatters_by_ft[ft])
      end
      -- extend opts.formatters_by_ft
      for ft, formatters_ in pairs(extend_formatters_with) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        vim.list_extend(opts.formatters_by_ft[ft], formatters_)
      end
      -- replace opts.formatters_by_ft
      for ft, formatters_ in pairs(replace_formatters_with) do
        opts.formatters_by_ft[ft] = formatters_
      end

      -- -- review opts.formatters_by_ft by uncommenting the below
      -- vim.api.nvim_echo(
      --   { { "opts.formatters_by_ft", "None" }, { vim.inspect(opts.formatters_by_ft), "None" } },
      --   false,
      --   {}
      -- )
    end,
  },
  {
    "mfussenegger/nvim-lint",
    ft = { "go" },
    opts = function(_, opts)
      local linters = require("lint").linters

      linters.golangcilint.args = use_golangci_config_if_available(linters)

      local linters_by_ft = {
        go = { "golangcilint" },
      }

      -- extend opts.linters_by_ft
      for ft, linters_ in pairs(linters_by_ft) do
        opts.linters_by_ft[ft] = opts.linters_by_ft[ft] or {}
        vim.list_extend(opts.linters_by_ft[ft], linters_)
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    ft = { "go" },
    optional = true,
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "delve" })
        end,
      },
      {
        "leoluz/nvim-dap-go",
        config = true,
      },
    },
  },
  {
    "nvim-neotest/neotest",
    ft = { "go" },
    optional = true,
    dependencies = {
      "nvim-neotest/neotest-go",
    },
    opts = {
      adapters = {
        ["neotest-go"] = {
          -- Here we can set options for neotest-go, e.g.
          -- args = { "-tags=integration" }
          args = { "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out" },
          -- TODO: figure out if this should be enabled: recursive_run = true,
        },
      },
    },
  },
  {
    "andythigpen/nvim-coverage",
    ft = { "go" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      auto_reload = true,
      lang = {
        go = {
          coverage_file = vim.fn.getcwd() .. "/coverage.out",
        },
      },
    },
  },
}
