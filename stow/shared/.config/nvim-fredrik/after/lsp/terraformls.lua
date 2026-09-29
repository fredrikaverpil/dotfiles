---@type vim.lsp.Config
return {
  cmd = { "terraform-ls", "serve" },
  filetypes = { "terraform", "tf", "terraform-vars" },
  root_markers = { ".terraform", "terraform" },
  -- Disable semantic tokens — terraform-ls responses for heredoc
  -- blocks with template interpolation freeze Neovim 0.12.
  -- Treesitter handles syntax highlighting instead.
  capabilities = {
    textDocument = {
      semanticTokens = vim.NIL,
    },
  },
}
