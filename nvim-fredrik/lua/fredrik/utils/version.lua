local M = {}

function M.is_neovim_0_12_0()
  return vim.fn.has("nvim-0.12") == 1
end

return M
