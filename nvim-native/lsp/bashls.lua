---@type vim.lsp.Config
return {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh" },
  root_markers = { ".git" },
}
