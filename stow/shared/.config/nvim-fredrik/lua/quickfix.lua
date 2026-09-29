-- Quickfix and location list utilities.

local M = {}

---@param diagnostic vim.Diagnostic
---@return string
function M.format_diagnostic_text(diagnostic)
  local severity = vim.diagnostic.severity[diagnostic.severity]
  local message = diagnostic.message:gsub("\n", " ")

  local namespace_name = nil
  if diagnostic.namespace then
    local ns_info = vim.diagnostic.get_namespace(diagnostic.namespace)
    if ns_info and ns_info.name then
      namespace_name = ns_info.name
    end
  end

  if namespace_name then
    if diagnostic.source and diagnostic.source ~= namespace_name then
      return string.format("[%s: %s] %s: %s", namespace_name, diagnostic.source, severity, message)
    else
      return string.format("[%s] %s: %s", namespace_name, severity, message)
    end
  elseif diagnostic.source then
    return string.format("[%s] %s: %s", diagnostic.source, severity, message)
  else
    return string.format("%s: %s", severity, message)
  end
end

---@param diagnostics vim.Diagnostic[]
---@return table[]
function M.diagnostics_to_qf_items(diagnostics)
  local items = {}
  for _, diag in ipairs(diagnostics) do
    table.insert(items, {
      bufnr = diag.bufnr or vim.api.nvim_get_current_buf(),
      lnum = diag.lnum + 1,
      col = diag.col + 1,
      text = M.format_diagnostic_text(diag),
      type = diag.severity == vim.diagnostic.severity.ERROR and "E"
        or diag.severity == vim.diagnostic.severity.WARN and "W"
        or diag.severity == vim.diagnostic.severity.INFO and "I"
        or "N",
    })
  end
  return items
end

---@param info table
---@return string[]
local function qf_text_func(info)
  local wininfo = vim.fn.getwininfo(info.winid)[1]
  local is_loclist = wininfo and wininfo.loclist == 1

  local items = is_loclist and vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
    or vim.fn.getqflist({ id = info.id, items = 0 }).items

  local lines = {}
  for idx = info.start_idx, info.end_idx do
    local item = items[idx]
    if not item then
      table.insert(lines, "")
    elseif is_loclist then
      table.insert(lines, string.format("%d:%d %s", item.lnum, item.col, item.text or ""))
    else
      local filename = vim.fn.bufname(item.bufnr)
      filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":~:.")
      table.insert(lines, string.format("%s:%d:%d %s", filename, item.lnum, item.col, item.text or ""))
    end
  end
  return lines
end

M.qf_text_func = qf_text_func

local auto_update_state = {
  enabled = false,
  list_type = nil, ---@type "loclist"|"qflist"|nil
  bufnr = nil,
}

local function reset_auto_update_state()
  auto_update_state.enabled = false
  auto_update_state.list_type = nil
  auto_update_state.bufnr = nil
end

local function setup_auto_update(list_type, bufnr)
  auto_update_state.enabled = true
  auto_update_state.list_type = list_type
  auto_update_state.bufnr = bufnr

  local group = vim.api.nvim_create_augroup("DiagnosticListAutoUpdate", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      if not auto_update_state.enabled then
        return
      end
      if auto_update_state.list_type == "loclist" then
        local diagnostics = vim.diagnostic.get(0)
        vim.fn.setloclist(0, M.diagnostics_to_qf_items(diagnostics))
      elseif auto_update_state.list_type == "qflist" then
        local diagnostics = vim.diagnostic.get()
        vim.fn.setqflist(M.diagnostics_to_qf_items(diagnostics))
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "qf",
    callback = function()
      vim.api.nvim_create_autocmd("WinClosed", {
        buffer = 0,
        once = true,
        callback = function()
          reset_auto_update_state()
          pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
        end,
      })
    end,
  })
end

local function cleanup_auto_update()
  reset_auto_update_state()
  pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
end

---@param list_type "loclist"|"qflist"
---@return boolean
local function is_list_open(list_type)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "qf" then
      local wininfo = vim.fn.getwininfo(win)[1]
      if list_type == "loclist" and wininfo and wininfo.loclist == 1 then
        return true
      elseif list_type == "qflist" and wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0 then
        return true
      end
    end
  end
  return false
end

---@param list_type "loclist"|"qflist"
local function toggle_list(list_type)
  local is_loclist = list_type == "loclist"

  if is_list_open(list_type) then
    cleanup_auto_update()
    vim.cmd(is_loclist and "lclose" or "cclose")
  else
    local current_win = vim.api.nvim_get_current_win()
    local diagnostics = is_loclist and vim.diagnostic.get(0) or vim.diagnostic.get()
    local items = M.diagnostics_to_qf_items(diagnostics)

    if is_loclist then
      vim.fn.setloclist(0, items)
      vim.cmd("lopen")
    else
      vim.fn.setqflist(items)
      vim.cmd("copen")
    end

    vim.api.nvim_set_current_win(current_win)
    setup_auto_update(list_type, is_loclist and vim.api.nvim_get_current_buf() or nil)
  end
end

function M.toggle_loclist()
  toggle_list("loclist")
end

function M.toggle_qflist()
  toggle_list("qflist")
end

---@param is_loclist boolean
---@param is_visual boolean
local function delete_items(is_loclist, is_visual)
  local get_list = is_loclist and function()
    return vim.fn.getloclist(0)
  end or vim.fn.getqflist
  local set_list = is_loclist and function(list)
    vim.fn.setloclist(0, list)
  end or vim.fn.setqflist

  local start_line, end_line
  if is_visual then
    -- '< and '> are only updated after leaving visual mode; read the live
    -- selection instead, then exit visual mode.
    start_line = vim.fn.line("v")
    end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local list = get_list()
  for i = end_line, start_line, -1 do
    table.remove(list, i)
  end
  set_list(list)

  local target_line = math.min(start_line, #list)
  if target_line > 0 then
    vim.cmd(tostring(target_line))
  end
end

function M.setup()
  vim.o.quickfixtextfunc = "v:lua.require'quickfix'.qf_text_func"

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    group = vim.api.nvim_create_augroup("quickfix", { clear = true }),
    callback = function(event)
      local bufnr = event.buf
      local wininfo = vim.fn.getwininfo(vim.fn.bufwinid(bufnr))[1]
      local is_loclist = wininfo and wininfo.loclist == 1

      vim.keymap.set("n", "dd", function()
        delete_items(is_loclist, false)
      end, { buffer = bufnr, desc = "Delete item" })
      vim.keymap.set("x", "d", function()
        delete_items(is_loclist, true)
      end, { buffer = bufnr, desc = "Delete items" })
    end,
  })
end

return M
