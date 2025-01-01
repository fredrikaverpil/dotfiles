M = {}

function M.is_neovim_0_10_0()
  return vim.fn.has("nvim-0.10") == 1
end

function M.is_neovim_0_11_0()
  return vim.fn.has("nvim-0.11") == 1
end

function M.setup_backwards_compat()
  if not M.is_neovim_0_10_0() then
    -- neovim 0.9.5+
    vim.uv = vim.loop -- vim.loop is deprecated in 0.10.0
  end

  if M.is_neovim_0_11_0() then
    vim.g.native_lsp = true -- use native lsp instead of lspconfig
  end
end

return M
