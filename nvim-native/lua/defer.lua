-- Deferred loading queues for startup performance.
--
-- on_vim_enter(fn):                    async fire-and-forget via vim.schedule() (default)
-- on_vim_enter(fn, { sync = true }):   synchronous, must complete before next phase
-- on_ui_enter(fn):                     async fire-and-forget via vim.schedule() (default)
-- on_ui_enter(fn, { sync = true }):    synchronous, must complete before next phase

local M = {}

local vim_enter_queue = {}
local ui_enter_queue = {}

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

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    drain(vim_enter_queue)
    vim_enter_queue = nil
  end,
})

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    drain(ui_enter_queue)
    ui_enter_queue = nil
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

--- Run at UIEnter. Async by default. Pass { sync = true } to run synchronously.
---@param fn fun()
---@param opts? { sync?: boolean }
function M.on_ui_enter(fn, opts)
  local sync = opts and opts.sync or false
  if ui_enter_queue then
    table.insert(ui_enter_queue, { fn = fn, sync = sync })
  elseif sync then
    fn()
  else
    vim.schedule(fn)
  end
end

return M
