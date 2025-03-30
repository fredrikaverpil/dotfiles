vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "gha", "dependabot" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true

    vim.opt_local.colorcolumn = "120" -- NOTE: also see yamllint config
  end,
})

vim.filetype.add({
  -- extension = {},
  -- filename = {},
  pattern = {
    -- can be comma-separated for a list of paths
    [".*/%.github/dependabot.yml"] = "dependabot",
    [".*/%.github/dependabot.yaml"] = "dependabot",
    [".*/%.github/workflows[%w/]+.*%.yml"] = "gha",
    [".*/%.github/workflows/[%w/]+.*%.yaml"] = "gha",
  },
})

-- use the yaml parser for the custom filetypes
vim.treesitter.language.register("yaml", "gha")
vim.treesitter.language.register("yaml", "dependabot")

return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "yamlfmt" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        -- https://github.com/google/yamlfmt
        yaml = { "yamlfmt" },
        gha = { "yamlfmt" },
        dependabot = { "yamlfmt" },
      },
      formatters = {
        yamlfmt = {
          prepend_args = {
            -- https://github.com/google/yamlfmt/blob/main/docs/config-file.md#configuration-1
            "-formatter",
            "retain_line_breaks_single=true",
          },
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
          vim.list_extend(opts.ensure_installed, { "yamllint", "actionlint" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        yaml = { "yamllint" },
        gha = { "actionlint" },
      },
      linters = {
        yamllint = {
          args = {
            "--config-file",
            require("fredrik.utils.environ").getenv("DOTFILES") .. "/templates/.yamllint.yml",
            "--format",
            "parsable",
            "-",
          },
        },
      },
    },
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "b0o/SchemaStore.nvim",
        version = false, -- last release is very old
      },
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "yamlls" })
        end,
      },
    },
    opts = function(_, opts)
      local defaults = {
        servers = {
          ---@type vim.lsp.Config
          yamlls = {
            -- lsp: https://github.com/redhat-developer/yaml-language-server
            -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/yamlls.lua
            cmd = { "yaml-language-server", "--stdio" },
            filetypes = { "yaml", "gha", "dependabot", "yaml", "yaml.docker-compose", "yaml.gitlab" },
            root_markers = { ".git" },
            settings = {
              -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
              redhat = { telemetry = { enabled = false } },
              yaml = {
                schemaStore = {
                  -- Disabled because using b0o/SchemaStore.nvim
                  enable = false,
                  -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                  url = "",
                },
                schemas = require("schemastore").yaml.schemas(),
                validate = true,
                format = {
                  enable = false, -- delegate to conform.nvim
                },
              },
            },
          },
        },
      }
      opts = require("fredrik.utils.table").deep_merge(opts, defaults)
      return opts
    end,
  },
}
