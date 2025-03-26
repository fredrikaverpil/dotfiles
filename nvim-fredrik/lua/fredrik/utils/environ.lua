local M = {}

---Get the value of an environment variable.
---Wraps os.getenv but always returns a string.
---@param name string
---@return string
function M.getenv(name)
  local envvar = os.getenv(name)
  if envvar == nil then
    vim.notify(name .. " environment variable is not set", vim.log.levels.WARN)
    return ""
  end
  return envvar
end

return M
