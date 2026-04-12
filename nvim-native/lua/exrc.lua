-- Custom exrc implementation.
--
-- Neovim's built-in 'exrc' (:h exrc) sources .nvim.lua at step 7c of
-- :h initialization — before plugin/ files (step 11). That means .nvim.lua
-- cannot call require("conform").setup() etc. because the plugins haven't been
-- set up yet. This module replaces it:
--
--   load()  — discovers .nvim.lua files from $HOME down to cwd (outermost
--             first), checks each with vim.secure.read() (:h trust) so
--             untrusted files prompt and denied files are skipped, then defers
--             execution via lazyload.on_override() which runs after all
--             VimEnter plugin setup. This means .nvim.lua files can call
--             plugin setup directly — no need to wrap content in on_override()
--             manually. Errors are caught with pcall and shown as vim.notify
--             messages instead of flashing by.
--
--   list()  — returns exrc files with their trust status (for the dashboard).
--
-- vim.opt.exrc is set to false in lua/options.lua to prevent the built-in
-- mechanism from double-sourcing the same files.

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

--- Source all .nvim.lua files from $HOME down to cwd (outermost first).
--- Uses vim.secure.read() for trust checking (:h trust) — untrusted files
--- prompt the user, denied files are silently skipped.
--- Errors are shown as notifications after UI is ready.
function M.load()
  local home = vim.uv.os_homedir()
  local files = {}
  local dir = vim.fn.getcwd()
  while true do
    local path = dir .. "/.nvim.lua"
    if vim.uv.fs_stat(path) then
      table.insert(files, 1, path) -- prepend so outermost runs first
    end
    if dir == home or dir == "/" then
      break
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  for _, path in ipairs(files) do
    local contents = vim.secure.read(path)
    if contents then
      require("lazyload")._on_override(function()
        local chunk, load_err = loadstring(contents, "@" .. path)
        if not chunk then
          vim.notify(load_err, vim.log.levels.ERROR)
          return
        end
        local ok, err = pcall(chunk)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end)
    end
  end
end

return M
