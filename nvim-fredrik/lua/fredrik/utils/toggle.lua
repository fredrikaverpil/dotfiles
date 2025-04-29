M = {}

local orig_fmt_func = vim.lsp.handlers["textDocument/formatting"]
local foldmethod = nil

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

function M.toggle_manual_folding()
  if foldmethod == "manual" then
    vim.wo.foldmethod = "expr"
    foldmethod = nil
    vim.notify("Foldmethod set to expr", vim.log.levels.INFO)
  else
    vim.wo.foldmethod = "manual"
    foldmethod = vim.wo.foldmethod
    vim.notify("Foldmethod set to manual", vim.log.levels.INFO)
  end
end

return M
