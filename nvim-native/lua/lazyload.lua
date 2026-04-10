-- Lazyload queues for phased plugin loading.
--
-- on_vim_enter(fn):                    async fire-and-forget via vim.schedule() (default)
-- on_vim_enter(fn, { sync = true }):   synchronous, must complete before next phase
-- on_ui_enter(fn):                     async fire-and-forget via vim.schedule() (default)
-- on_ui_enter(fn, { sync = true }):    synchronous, must complete before next phase
-- on_override(fn):                     runs after all on_vim_enter callbacks (for .nvim.lua overrides)
--
-- Logging: set vim.g.lazyload_log = true before require("lazyload") to trace
-- registration and execution order. Inspect with :LazyLoadLog.

local M = {}

local vim_enter_queue = {}
local ui_enter_queue = {}
local override_queue = {}

-- Logging (opt-in via vim.g.lazyload_log = true)
local log_enabled = vim.g.lazyload_log or false
local log_entries = {}
local start_time = vim.uv.hrtime()

---@param event string
---@param source? string
local function log(event, source)
  if not log_enabled then
    return
  end
  local ms = ("%.3f"):format((vim.uv.hrtime() - start_time) / 1e6)
  table.insert(log_entries, ms .. "ms  " .. event .. (source and ("  ← " .. source) or ""))
end

--- Get the caller's source file (2 levels up: log caller → public API → actual caller).
---@return string?
local function caller_source()
  if not log_enabled then
    return nil
  end
  local info = debug.getinfo(3, "S")
  if info and info.source then
    return info.source:gsub("^@", ""):gsub(".*/nvim%-native/", "")
  end
  return "?"
end

---@param queue { fn: fun(), sync: boolean, source: string }[]
---@param queue_name string
local function drain(queue, queue_name)
  log("drain " .. queue_name .. " (" .. #queue .. " entries)")
  for _, entry in ipairs(queue) do
    if not entry.sync then
      local source = entry.source
      vim.schedule(function()
        log("exec async " .. queue_name, source)
        entry.fn()
      end)
    end
  end
  for _, entry in ipairs(queue) do
    if entry.sync then
      log("exec sync " .. queue_name, entry.source)
      entry.fn()
    end
  end
end

--- Schedule overrides last, after both VimEnter and UIEnter queues have been
--- drained. Idempotent so VimEnter (headless fallback) and UIEnter can both
--- call it without double-running callbacks.
local function drain_override()
  if not override_queue then
    return
  end
  log("drain override (" .. #override_queue .. " entries)")
  for _, entry in ipairs(override_queue) do
    local source = entry.source
    vim.schedule(function()
      log("exec override", source)
      entry.fn()
    end)
  end
  override_queue = nil
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    log("VimEnter fired")
    drain(vim_enter_queue, "vim_enter")
    vim_enter_queue = nil
    -- Headless Neovim (nvim --headless) never fires UIEnter, so we must drain
    -- overrides here as a fallback. In interactive mode, UIEnter drains them
    -- so they land after ui_enter_queue's async entries in the scheduler.
    if #vim.api.nvim_list_uis() == 0 then
      drain_override()
    end
  end,
})

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    log("UIEnter fired")
    drain(ui_enter_queue, "ui_enter")
    ui_enter_queue = nil
    drain_override()
  end,
})

--- Run at VimEnter. Async by default. Pass { sync = true } to run synchronously.
---@param fn fun()
---@param opts? { sync?: boolean }
function M.on_vim_enter(fn, opts)
  local sync = opts and opts.sync or false
  local source = caller_source()
  log("register vim_enter" .. (sync and " (sync)" or ""), source)
  if vim_enter_queue then
    table.insert(vim_enter_queue, { fn = fn, sync = sync, source = source })
  elseif sync then
    fn()
  else
    vim.schedule(fn)
  end
end

--- Run at UIEnter. Async by default. Pass { sync = true } to run synchronously.
---@param fn fun()
---@param opts? { sync?: boolean }
function M.on_ui_enter(fn, opts)
  local sync = opts and opts.sync or false
  local source = caller_source()
  log("register ui_enter" .. (sync and " (sync)" or ""), source)
  if ui_enter_queue then
    table.insert(ui_enter_queue, { fn = fn, sync = sync, source = source })
  elseif sync then
    fn()
  else
    vim.schedule(fn)
  end
end

--- Run after all on_vim_enter callbacks (including async ones) have executed.
--- Intended for project-local overrides from .nvim.lua that need to patch
--- plugin state after setup() has run. Exrc runs at step 7c — before plugin/
--- files — so it cannot override plugin setup directly; this queue bridges
--- that gap by registering a callback that runs after the VimEnter drain.
---@param fn fun()
function M.on_override(fn)
  local source = caller_source()
  log("register override", source)
  if override_queue then
    table.insert(override_queue, { fn = fn, source = source })
  else
    vim.schedule(fn)
  end
end

--- Return collected log entries.
---@return string[]
function M.log()
  return log_entries
end

if log_enabled then
  vim.api.nvim_create_user_command("LazyLoadLog", function()
    if #log_entries == 0 then
      vim.notify("lazyload: no log entries (vim.g.lazyload_log not set at startup?)", vim.log.levels.WARN)
      return
    end
    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.filetype = "log"
    vim.api.nvim_buf_set_name(0, "lazyload-log")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, log_entries)
  end, { desc = "Show lazyload.lua execution log" })
end

return M
