local M = {}

--- Returns true if the current working directory is at or below `root`.
---@param root string path, may contain `~`
---@return boolean
function M.cwd_is_under(root)
  local cwd = vim.fn.getcwd()
  root = vim.fn.expand(root)
  return cwd == root or cwd:sub(1, #root + 1) == root .. "/"
end

return M
