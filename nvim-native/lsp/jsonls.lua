vim.pack.add({
  { src = "https://github.com/b0o/SchemaStore.nvim" },
})

---@type vim.lsp.Config
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc", "json5" },
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
}
