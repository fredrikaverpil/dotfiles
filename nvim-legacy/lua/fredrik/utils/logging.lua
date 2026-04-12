local M = {}

---@class LogOptions
---@field enabled? boolean Enable or disable logging (default: true)
---@field max_size? number Maximum log file size in bytes before truncation (default: 1048576)

---Log output to a file with timestamp in stdpath("log").
---Truncates the log file if it exceeds max_size.
---@param output string The content to log
---@param filename string The log filename (e.g., "api-linter.log")
---@param opts? LogOptions Optional configuration
function M.log_output(output, filename, opts)
  opts = opts or {}
  local enabled = opts.enabled ~= false -- default true
  local max_size = opts.max_size or (1024 * 1024) -- default 1MB

  if not enabled then
    return
  end

  local log_path = vim.fn.stdpath("log") .. "/" .. filename

  -- Check file size and truncate if too large
  local stat = vim.uv.fs_stat(log_path)
  local mode = "a"
  if stat and stat.size > max_size then
    mode = "w" -- Truncate and start fresh
  end

  -- Write to log file
  local f = io.open(log_path, mode)
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. "\n" .. output .. "\n---\n")
    f:close()
  end
end

return M
