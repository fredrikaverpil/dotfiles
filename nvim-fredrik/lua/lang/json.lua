local filetypes = { "json", "jsonc", "json5" }

-- Fix conceallevel for json files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("json_conceal", { clear = true }),
  pattern = filetypes,
  callback = function()
    vim.opt_local.conceallevel = 0
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
          vim.list_extend(opts.ensure_installed, { "biome" })
        end,
      },
    },
    ft = filetypes,
    opts = {
      formatters_by_ft = {
        json = { "biome" },
        jsonc = { "biome" },
        json5 = { "biome" },
      },
      formatters = {
        biome = {
          -- https://biomejs.dev/formatter/
          args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "b0o/SchemaStore.nvim",
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
          vim.list_extend(opts.ensure_installed, { "jsonls" })
        end,
      },
    },
    ft = filetypes,
    opts = {
      servers = {
        jsonls = {
          -- https://github.com/microsoft/vscode-json-languageservice
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
      },
    },
  },
}
