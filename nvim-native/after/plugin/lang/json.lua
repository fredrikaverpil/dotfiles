-- JSON: formatters and LSP schema config.

require("conform").setup({
  formatters_by_ft = {
    json = { "biome" },
    jsonc = { "biome" },
    json5 = { "biome" },
  },
  formatters = {
    biome = {
      args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
    },
  },
})

-- Add SchemaStore schemas to jsonls (SchemaStore.nvim is loaded by plugin/schemastore.lua)
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})
