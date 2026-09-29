vim.pack.add({
  { src = "https://github.com/b0o/SchemaStore.nvim" },
})

---@type vim.lsp.Config
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "gha", "dependabot", "yaml.docker-compose", "yaml.gitlab" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = {
        enable = false, -- using b0o/SchemaStore.nvim instead
        url = "", -- avoid TypeError
      },
      schemas = require("schemastore").yaml.schemas(),
      validate = true,
      format = {
        enable = false, -- delegate to conform.nvim
      },
    },
  },
}
