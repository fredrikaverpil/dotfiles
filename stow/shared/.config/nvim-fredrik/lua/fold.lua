local M = {}

function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  local line_text = vim.fn.substitute(line, "\t", " ", "g")
  return string.format("%s (%d lines)", line_text, line_count)
end

--- Override foldexpr with LSP folding for the current window/buffer.
---@param win integer window handle
function M.lsp_foldexpr(win)
  vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
end

return M
