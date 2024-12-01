M = {}

function M.toggle_formatting()
  vim.g.auto_format = not vim.g.auto_format -- reverse the value

  if vim.g.auto_format then
    print("Auto-formatting enabled", vim.log.levels.INFO)
  else
    print("Auto-formatting disabled", vim.log.levels.INFO)
  end
end

function M.toggle_inlay_hints()
  local filter = {}
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter))
end

return M
