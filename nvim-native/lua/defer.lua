-- Deferred loading queues for startup performance.
--
-- on_vim_enter(fn, { async = true }):  fire-and-forget via vim.schedule()
-- on_vim_enter(fn):                    synchronous (default)
-- on_ui_enter(fn, { async = true }):   fire-and-forget via vim.schedule()
-- on_ui_enter(fn):                     synchronous (default)

local M = {}

local vim_enter_queue = {}
local ui_enter_queue = {}

---@param queue { fn: fun(), async: boolean }[]
local function drain(queue)
  for _, entry in ipairs(queue) do
    if entry.async then
      vim.schedule(entry.fn)
    end
  end
  for _, entry in ipairs(queue) do
    if not entry.async then
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

--- Run at VimEnter. Pass { async = true } to fire-and-forget via vim.schedule().
---@param fn fun()
---@param opts? { async?: boolean }
function M.on_vim_enter(fn, opts)
  local async = opts and opts.async or false
  if vim_enter_queue then
    table.insert(vim_enter_queue, { fn = fn, async = async })
  elseif async then
    vim.schedule(fn)
  else
    fn()
  end
end

--- Run at UIEnter. Pass { async = true } to fire-and-forget via vim.schedule().
---@param fn fun()
---@param opts? { async?: boolean }
function M.on_ui_enter(fn, opts)
  local async = opts and opts.async or false
  if ui_enter_queue then
    table.insert(ui_enter_queue, { fn = fn, async = async })
  elseif async then
    vim.schedule(fn)
  else
    fn()
  end
end

return M
