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
          vim.list_extend(opts.ensure_installed, { "jsonls" })
        end,
      },
    },
    opts = function(_, opts)
      local defaults = {
        servers = {
          ---@type vim.lsp.Config
          jsonls = {
            -- lsp: https://github.com/microsoft/vscode-json-languageservice
            -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/jsonls.lua
            cmd = { "vscode-json-language-server", "--stdio" },
            filetypes = filetypes,
            root_markers = { ".git" },
            init_options = {
              provideFormatter = false, -- use conform.nvim instead
            },
            settings = {
              json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
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
