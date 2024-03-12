M = {}

M.toggle_formatting = function()
  vim.g.auto_format = not vim.g.auto_format -- reverse the value

  if vim.g.auto_format then
    vim.notify("Auto-formatting enabled", vim.log.levels.INFO)
  else
    vim.notify("Auto-formatting disabled", vim.log.levels.INFO)
  end
end

return M
