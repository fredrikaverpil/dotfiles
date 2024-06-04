M = {}

function M.toggle_inlay_hints()
  if vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].buftype == "" then
    local filter = {}
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter))
  end
end

return M
