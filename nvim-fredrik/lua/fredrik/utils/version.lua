M = {}

function M.is_neovim_0_12_0()
  return vim.fn.has("nvim-0.12") == 1
end

function M.is_neovim_0_11_0()
  return vim.fn.has("nvim-0.11") == 1
end

function M.is_neovim_0_10_0()
  return vim.fn.has("nvim-0.10") == 1
end

function M.setup_backwards_compat()
  -- no op for now
end

return M
