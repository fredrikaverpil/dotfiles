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

--- Load a local plugin directory: prepend to runtimepath and source plugin/ files.
--- Follows :h initialization step 11 order. Returns false if the path doesn't exist.
---@param local_path string
---@return boolean
function m.load_local(local_path)
  local expanded = vim.fs.normalize(vim.fn.expand(local_path))
  if not vim.uv.fs_stat(expanded) then
    return false
  end
  vim.opt.runtimepath:prepend(expanded)
  for _, pattern in ipairs({
    "/plugin/**/*.vim",
    "/plugin/**/*.lua",
    "/after/plugin/**/*.vim",
    "/after/plugin/**/*.lua",
  }) do
    for _, f in ipairs(vim.fn.glob(expanded .. pattern, false, true)) do
      vim.cmd.source(f)
    end
  end
  return true
end

return m
