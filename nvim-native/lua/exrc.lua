-- Discover project-local exrc files and their trust status.
-- See :h 'exrc' and runtime/lua/vim/_core/exrc.lua.

local M = {}

---@class ExrcEntry
---@field path string           Display path (tilde-expanded)
---@field status "trusted"|"modified"|"denied"|"untrusted"|"unreadable"

--- Read the trust DB without prompting. vim.secure.read() would pop a
--- confirm dialog on untrusted files, which is unusable from non-interactive
--- contexts like the dashboard.
local function read_trust_db()
  local trust = {}
  local f = io.open(vim.fn.stdpath("state") .. "/trust", "r")
  if not f then
    return trust
  end
  for line in f:lines() do
    local hash, path = line:match("^(%S+) (.+)$")
    if hash and path then
      trust[path] = hash
    end
  end
  f:close()
  return trust
end

local function classify(real, trust)
  local stored = trust[real]
  if stored == "!" then
    return "denied"
  end
  if not stored then
    return "untrusted"
  end
  local fh = io.open(real, "rb")
  if not fh then
    return "unreadable"
  end
  local data = fh:read("*a")
  fh:close()
  return vim.fn.sha256(data) == stored and "trusted" or "modified"
end

--- List exrc files found upward from cwd with their trust status.
---@return ExrcEntry[]
function M.list()
  local found = vim.fs.find({ ".nvim.lua", ".nvimrc", ".exrc" }, {
    upward = true,
    type = "file",
    limit = math.huge,
  })
  if #found == 0 then
    return {}
  end

  local trust = read_trust_db()
  local entries = {}
  for _, path in ipairs(found) do
    local real = vim.uv.fs_realpath(vim.fs.normalize(path)) or path
    table.insert(entries, {
      path = vim.fn.fnamemodify(path, ":~"),
      status = classify(real, trust),
    })
  end
  return entries
end

return M
