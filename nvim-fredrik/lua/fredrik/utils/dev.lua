local M = {}

--- Return local path, if it exists, or nil
function M.local_path(path)
  if vim.fn.isdirectory(vim.fn.expand(path)) == 0 then
    return nil
  end
  return path
end

return M
