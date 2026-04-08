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
      -- schemas are added via after/plugin/lang/yaml.lua (SchemaStore must load first)
      validate = true,
      format = {
        enable = false, -- delegate to conform.nvim
      },
    },
  },
}
