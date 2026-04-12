local m = {}

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
