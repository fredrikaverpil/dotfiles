---@type vim.lsp.Config
return {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = { "graphql" },
}
