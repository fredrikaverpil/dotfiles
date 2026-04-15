-- Lazyload queues for phased plugin loading.
--
-- on_vim_enter(fn):                    async fire-and-forget via vim.schedule() (default)
-- on_vim_enter(fn, { sync = true }):   synchronous, must complete before next phase
-- on_override(fn):                     runs after all on_vim_enter callbacks (for .nvim.lua overrides)

local M = {}

local vim_enter_queue = {}
local override_queue = {}

---@param queue { fn: fun(), sync: boolean }[]
local function drain(queue)
  for _, entry in ipairs(queue) do
    if not entry.sync then
      vim.schedule(entry.fn)
    end
  end
  for _, entry in ipairs(queue) do
    if entry.sync then
      entry.fn()
    end
  end
end

local function drain_override()
  if not override_queue then
    return
  end
  for _, entry in ipairs(override_queue) do
    vim.schedule(function()
      local ok, err = pcall(entry.fn)
      if not ok then
        vim.notify((".nvim.lua override error:\n%s"):format(err), vim.log.levels.ERROR)
      end
    end)
  end
  override_queue = nil
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    drain(vim_enter_queue)
    vim_enter_queue = nil
    drain_override()
  end,
})

--- Run at VimEnter. Async by default. Pass { sync = true } to run synchronously.
---@param fn fun()
---@param opts? { sync?: boolean }
function M.on_vim_enter(fn, opts)
  local sync = opts and opts.sync or false
  if vim_enter_queue then
    table.insert(vim_enter_queue, { fn = fn, sync = sync })
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
  if override_queue then
    table.insert(override_queue, { fn = fn })
  else
    vim.schedule(fn)
  end
end

-- Call function only once.
function M.call_once(fn)
  local id = tostring(fn)
  if fn and not Config.called[id] then
    fn()
    Config.called[id] = true
  end
end

return M
