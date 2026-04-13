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

--- load a plugin from a local dev clone if it exists, otherwise via a fallback.
---@param opts { dev: string, fallback: fun() }
function m.use(opts)
  local dev_path = vim.fn.expand(opts.dev)
  if vim.uv.fs_stat(dev_path) then
    vim.opt.runtimepath:append(dev_path)
  else
    opts.fallback()
  end
end

return m
