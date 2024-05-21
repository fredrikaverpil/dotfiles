M = {}

function M.toggle_inlay_hints()
  local filter = {}
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter))
end

return M
