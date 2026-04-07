local M = {}

function M.auto_format()
  vim.g.auto_format = not vim.g.auto_format
  vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
end

function M.inlay_hints()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
end

function M.diagnostics()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  vim.notify("Diagnostics: " .. (vim.diagnostic.is_enabled() and "on" or "off"))
end

function M.codelens()
  local enabled = not vim.lsp.codelens.is_enabled()
  vim.lsp.codelens.enable(enabled)
  vim.notify("Codelens: " .. (enabled and "on" or "off"))
end

return M
