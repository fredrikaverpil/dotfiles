M = {}

function M.toggle_formatting()
  vim.g.auto_format = not vim.g.auto_format -- reverse the value

  if vim.g.auto_format then
    print("Auto-formatting enabled", vim.log.levels.INFO)
  else
    print("Auto-formatting disabled", vim.log.levels.INFO)
  end
end

return M
