-- Deferred loading queues for startup performance.
-- Lets the dashboard paint before heavy plugin setup runs.

local M = {}

local vim_enter_queue = {}
local ui_enter_queue = {}

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    for _, fn in ipairs(vim_enter_queue) do
      fn()
    end
    vim_enter_queue = nil
  end,
})

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.cmd("redraw")
      for _, fn in ipairs(ui_enter_queue) do
        fn()
      end
      ui_enter_queue = nil
    end)
  end,
})

--- Run at VimEnter (before first paint, after all plugin/ files).
---@param fn fun()
function M.on_vim_enter(fn)
  if vim_enter_queue then
    table.insert(vim_enter_queue, fn)
  else
    fn()
  end
end

--- Run after first paint (UIEnter + vim.schedule + redraw).
---@param fn fun()
function M.on_ui_enter(fn)
  if ui_enter_queue then
    table.insert(ui_enter_queue, fn)
  else
    fn()
  end
end

return M
