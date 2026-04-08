---@type vim.lsp.Config
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc", "json5" },
  root_markers = { ".git" },
  init_options = {
    provideFormatter = false, -- use conform.nvim instead
  },
  -- schemas are added via after/plugin/lang/json.lua (SchemaStore must load first)
}
