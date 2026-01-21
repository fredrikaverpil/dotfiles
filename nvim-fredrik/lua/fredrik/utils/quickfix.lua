local M = {}

--- Format a diagnostic with namespace and source information
---@param diagnostic vim.Diagnostic
---@return string
function M.format_diagnostic_text(diagnostic)
  local severity = vim.diagnostic.severity[diagnostic.severity]
  local message = diagnostic.message:gsub("\n", " ")

  -- Get namespace name (e.g., LSP server name, linter name, etc.)
  local namespace_name = nil
  if diagnostic.namespace then
    local ns_info = vim.diagnostic.get_namespace(diagnostic.namespace)
    if ns_info and ns_info.name then
      namespace_name = ns_info.name
    end
  end

  -- Format with namespace and/or source information
  if namespace_name then
    if diagnostic.source and diagnostic.source ~= namespace_name then
      -- Show both namespace and source if they differ
      return string.format("[%s: %s] %s: %s", namespace_name, diagnostic.source, severity, message)
    else
      -- Show only namespace
      return string.format("[%s] %s: %s", namespace_name, severity, message)
    end
  elseif diagnostic.source then
    -- Show only source if no namespace
    return string.format("[%s] %s: %s", diagnostic.source, severity, message)
  else
    -- No namespace or source
    return string.format("%s: %s", severity, message)
  end
end

--- Convert diagnostics to quickfix/location list items
---@param diagnostics vim.Diagnostic[]
---@return table[] quickfix/loclist items
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

--- Custom text function for quickfix/location list formatting
---@param info table
---@return string[]
local function qf_text_func(info)
  -- Determine if this is a location list or quickfix list
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
      -- Location list: just show the diagnostic text without filename/position
      table.insert(lines, item.text or "")
    else
      -- Quickfix list: show default format with filename and position
      local filename = vim.fn.bufname(item.bufnr)
      filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":~:.")
      -- With position:
      table.insert(lines, string.format("%s|%d col %d| %s", filename, item.lnum, item.col, item.text or ""))
      --
      -- Without position:
      -- table.insert(lines, string.format("%s %s", filename, item.text or ""))
    end
  end
  return lines
end

--- Set the custom text function globally
local function setup_qf_format()
  vim.o.quickfixtextfunc = "v:lua.require'fredrik.utils.quickfix'.qf_text_func"
end

-- Expose the function so it can be called from vim
M.qf_text_func = qf_text_func

-- Track which type of list is being auto-updated
local auto_update_state = {
  enabled = false,
  list_type = nil, -- "loclist" or "qflist"
  bufnr = nil, -- For loclist, track which window's loclist
}

--- Reset auto-update state
local function reset_auto_update_state()
  auto_update_state.enabled = false
  auto_update_state.list_type = nil
  auto_update_state.bufnr = nil
end

--- Set up auto-update for diagnostic lists on buffer save
local function setup_auto_update(list_type, bufnr)
  auto_update_state.enabled = true
  auto_update_state.list_type = list_type
  auto_update_state.bufnr = bufnr

  -- Create autocommand group for auto-updating
  local group = vim.api.nvim_create_augroup("DiagnosticListAutoUpdate", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      if not auto_update_state.enabled then
        return
      end

      -- Refresh the appropriate list
      if auto_update_state.list_type == "loclist" then
        local diagnostics = vim.diagnostic.get(0)
        local items = M.diagnostics_to_qf_items(diagnostics)
        vim.fn.setloclist(0, items)
      elseif auto_update_state.list_type == "qflist" then
        local diagnostics = vim.diagnostic.get()
        local items = M.diagnostics_to_qf_items(diagnostics)
        vim.fn.setqflist(items)
      end
    end,
  })

  -- Clean up when the quickfix/loclist window is closed
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "qf",
    callback = function()
      vim.api.nvim_create_autocmd("WinClosed", {
        buffer = 0,
        once = true,
        callback = function()
          reset_auto_update_state()
          -- Safely delete the autocommand group (might already be deleted by toggle)
          pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
        end,
      })
    end,
  })
end

--- Clean up auto-update state and autocommands
local function cleanup_auto_update()
  reset_auto_update_state()
  -- Safely delete the autocommand group
  pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
end

--- Check if a specific list type is open
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

--- Toggle diagnostics in list with auto-update
---@param list_type "loclist"|"qflist"
local function toggle_list(list_type)
  local is_loclist = list_type == "loclist"

  if is_list_open(list_type) then
    cleanup_auto_update()
    vim.cmd(is_loclist and "lclose" or "cclose")
  else
    -- Save current window to return focus after opening
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

    -- Return focus to the original window
    vim.api.nvim_set_current_win(current_win)
    setup_auto_update(list_type, is_loclist and vim.api.nvim_get_current_buf() or nil)
  end
end

--- Toggle buffer diagnostics in location list with auto-update
function M.toggle_loclist()
  toggle_list("loclist")
end

--- Toggle workspace diagnostics in quickfix list with auto-update
function M.toggle_qflist()
  toggle_list("qflist")
end

--- Delete item(s) from quickfix or location list
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
    start_line = vim.fn.line("'<")
    end_line = vim.fn.line("'>")
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local list = get_list()

  -- Remove items in reverse order to maintain indices
  for i = end_line, start_line, -1 do
    table.remove(list, i)
  end

  set_list(list)

  -- Move cursor to appropriate line
  local target_line = math.min(start_line, #list)
  if target_line > 0 then
    vim.cmd(tostring(target_line))
  end
end

--- Set up keymaps for quickfix/location list editing
function M.setup_qf_keymaps()
  -- Set up custom formatting globally
  setup_qf_format()

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(event)
      local bufnr = event.buf

      -- Determine if this is a location list or quickfix list
      local wininfo = vim.fn.getwininfo(vim.fn.bufwinid(bufnr))[1]
      local is_loclist = wininfo and wininfo.loclist == 1

      if is_loclist then
        -- Location list keymaps
        vim.keymap.set("n", "dd", function()
          delete_items(true, false)
        end, { buffer = bufnr, desc = "Delete location list item" })
        vim.keymap.set("x", "d", function()
          delete_items(true, true)
        end, { buffer = bufnr, desc = "Delete location list items" })
      else
        -- Quickfix list keymaps
        vim.keymap.set("n", "dd", function()
          delete_items(false, false)
        end, { buffer = bufnr, desc = "Delete quickfix item" })
        vim.keymap.set("x", "d", function()
          delete_items(false, true)
        end, { buffer = bufnr, desc = "Delete quickfix items" })
      end
    end,
  })
end

return M
