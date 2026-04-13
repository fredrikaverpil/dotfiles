local m = {}

--- Prefer local directory if it exists, otherwise fall back to remote source.
---@param local_path string
---@param remote_src string
---@return string
function m.prefer_local(local_path, remote_src)
  local expanded = vim.fs.normalize(vim.fn.expand(local_path))
  if vim.uv.fs_stat(expanded) then
    return expanded
  end
  return remote_src
end

return m
