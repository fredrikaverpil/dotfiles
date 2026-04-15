-- Exrc helpers for querying .nvim.lua files and their trust status.
--
-- list() — returns .nvim.lua files found upward from cwd with trust status.
--          Reads the trust DB directly (no prompting).

local M = {}

--- @class ExrcEntry
--- @field path string   Display path (tilde-collapsed)
--- @field status "trusted"|"modified"|"denied"|"untrusted"

--- List .nvim.lua files found upward from cwd with their trust status.
--- @return ExrcEntry[]
function M.list()
  local found = vim.fs.find(".nvim.lua", { upward = true, type = "file", limit = math.huge })
  if #found == 0 then
    return {}
  end

  local trust = {}
  local f = io.open(vim.fn.stdpath("state") .. "/trust", "r")
  if f then
    for line in f:lines() do
      local hash, path = line:match("^(%S+) (.+)$")
      if hash and path then
        trust[path] = hash
      end
    end
    f:close()
  end

  local entries = {}
  for _, path in ipairs(found) do
    local real = vim.uv.fs_realpath(vim.fs.normalize(path)) or path
    local stored = trust[real]
    local status
    if stored == "!" then
      status = "denied"
    elseif not stored then
      status = "untrusted"
    else
      local fh = io.open(real, "rb")
      if fh then
        local data = fh:read("*a")
        fh:close()
        status = vim.fn.sha256(data) == stored and "trusted" or "modified"
      else
        status = "untrusted"
      end
    end
    table.insert(entries, {
      path = vim.fn.fnamemodify(path, ":~"),
      status = status,
    })
  end
  return entries
end

return M
