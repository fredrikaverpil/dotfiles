vim.filetype.add({
  -- extension = {},
  -- filename = {},
  pattern = {
    -- can be comma-separated for a list of paths
    [".*/%.github[%w/]+.*%.yml"] = "gha",
    [".*/%.github[%w/]+.*%.yaml"] = "gha",
  },
})

-- the gha filetype will use the yaml parser and queries.
vim.treesitter.language.register("yaml", "gha")

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
    ft = { "yaml", "gha" },
    opts = {
      formatters_by_ft = {
        -- TODO: the default is very strict, might be good to add a config
        -- file: https://github.com/google/yamlfmt/blob/main/docs/config-file.md#basic-formatter
        yaml = { "yamlfmt" },
        gha = { "yamlfmt" },
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
          vim.list_extend(opts.ensure_installed, { "actionlint" })
        end,
      },
    },
    ft = { "gha" },
    opts = {
      linters_by_ft = {
        gha = { "actionlint" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "b0o/SchemaStore.nvim",
        version = false, -- last release is very old
      },
      { "kevinhwang91/nvim-ufo" },
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
    ft = { "yaml", "gha" },
    opts = {
      servers = {
        yamlls = {
          -- https://github.com/redhat-developer/yaml-language-server
          filetypes = { "yaml", "gha" },

          -- Have to add this for yamlls to understand that we support line folding
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },

          settings = {
            yaml = {
              -- SchemaStore setup below
              schemaStore = {
                -- You must disable built-in schemaStore support if you want to use
                -- this plugin and its advanced options like `ignore`.
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
      },
    },
  },
}
