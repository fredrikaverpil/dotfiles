vim.pack.add({
  { src = "https://github.com/b0o/SchemaStore.nvim" },
})

require("registry").add({
  lsp_servers = { "jsonls" },
  mason_tools = { "json-lsp", "biome" },
  conform = {
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
  },
})

-- Defer SchemaStore catalog loading (~7ms) until a JSON file is opened.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc", "json5" },
  once = true,
  callback = function()
    vim.lsp.config("jsonls", {
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = { enable = true },
        },
      },
    })
  end,
})
