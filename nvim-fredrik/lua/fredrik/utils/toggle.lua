M = {}

local orig_fmt_func = vim.lsp.handlers["textDocument/formatting"]

function M.toggle_formatting()
  vim.g.auto_format = not vim.g.auto_format -- reverse the value

  if vim.g.auto_format then
    vim.lsp.handlers["textDocument/formatting"] = orig_fmt_func
  else
    vim.lsp.handlers["textDocument/formatting"] = function() end
  end

  if vim.g.auto_format then
    vim.notify("Auto-formatting enabled", vim.log.levels.INFO)
  else
    vim.notify("Auto-formatting disabled", vim.log.levels.INFO)
  end
end

function M.toggle_inlay_hints()
  local filter = {}
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter))
end

return M
