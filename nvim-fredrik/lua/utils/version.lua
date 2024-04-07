M = {}

function M.is_neovim_0_10_0()
  return vim.fn.has("nvim-0.10") == 1
end

function M.setup_backwards_compat()
  if not M.is_neovim_0_10_0() then
    -- neovim 0.9.5+
    vim.uv = vim.loop -- vim.loop is deprecated in 0.10.0
  end
end

return M
