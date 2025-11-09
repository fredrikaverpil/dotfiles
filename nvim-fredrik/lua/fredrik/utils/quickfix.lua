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

  local items
  if is_loclist then
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  else
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  end

  local lines = {}
  for idx = info.start_idx, info.end_idx do
    local item = items[idx]
    -- Safety check: if item doesn't exist, use default format
    if not item then
      table.insert(lines, "")
      goto continue
    end

    local text = item.text or ""

    if is_loclist then
      -- Location list: just show the diagnostic text without filename/position
      table.insert(lines, text)
    else
      -- Quickfix list: show default format with filename and position
      local filename = vim.fn.bufname(item.bufnr)
      if filename == "" then
        filename = "[No Name]"
      else
        filename = vim.fn.fnamemodify(filename, ":~:.")
      end
      local lnum = item.lnum
      local col = item.col
      table.insert(lines, string.format("%s|%d col %d| %s", filename, lnum, col, text))
    end

    ::continue::
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
          auto_update_state.enabled = false
          auto_update_state.list_type = nil
          auto_update_state.bufnr = nil
          -- Safely delete the autocommand group (might already be deleted by toggle)
          pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
        end,
      })
    end,
  })
end

--- Clean up auto-update state and autocommands
local function cleanup_auto_update()
  auto_update_state.enabled = false
  auto_update_state.list_type = nil
  auto_update_state.bufnr = nil
  -- Safely delete the autocommand group
  pcall(vim.api.nvim_del_augroup_by_name, "DiagnosticListAutoUpdate")
end

--- Check if location list is open for the current window
---@return boolean
local function is_loclist_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "qf" then
      -- Check if it's a location list (not quickfix)
      local wininfo = vim.fn.getwininfo(win)[1]
      if wininfo and wininfo.loclist == 1 then
        return true
      end
    end
  end
  return false
end

--- Check if quickfix list is open
---@return boolean
local function is_qflist_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "qf" then
      -- Check if it's a quickfix (not location list)
      local wininfo = vim.fn.getwininfo(win)[1]
      if wininfo and wininfo.quickfix == 1 and wininfo.loclist == 0 then
        return true
      end
    end
  end
  return false
end

--- Toggle buffer diagnostics in location list with auto-update
function M.toggle_loclist()
  if is_loclist_open() then
    cleanup_auto_update()
    vim.cmd("lclose")
  else
    -- Save current window to return focus after opening
    local current_win = vim.api.nvim_get_current_win()
    local diagnostics = vim.diagnostic.get(0)
    local items = M.diagnostics_to_qf_items(diagnostics)
    vim.fn.setloclist(0, items)
    vim.cmd("lopen")
    -- Return focus to the original window
    vim.api.nvim_set_current_win(current_win)
    setup_auto_update("loclist", vim.api.nvim_get_current_buf())
  end
end

--- Toggle workspace diagnostics in quickfix list with auto-update
function M.toggle_qflist()
  if is_qflist_open() then
    cleanup_auto_update()
    vim.cmd("cclose")
  else
    -- Save current window to return focus after opening
    local current_win = vim.api.nvim_get_current_win()
    local diagnostics = vim.diagnostic.get()
    local items = M.diagnostics_to_qf_items(diagnostics)
    vim.fn.setqflist(items)
    vim.cmd("copen")
    -- Return focus to the original window
    vim.api.nvim_set_current_win(current_win)
    setup_auto_update("qflist", nil)
  end
end

--- Delete the current item from the quickfix list
local function delete_qf_item()
  local qf_idx = vim.fn.line(".")
  local qf_list = vim.fn.getqflist()
  table.remove(qf_list, qf_idx)
  vim.fn.setqflist(qf_list)
  -- Stay on the same line if possible, otherwise move up
  if qf_idx > #qf_list then
    qf_idx = #qf_list
  end
  if qf_idx > 0 then
    vim.cmd(tostring(qf_idx))
  end
end

--- Delete the current item from the location list
local function delete_loc_item()
  local loc_idx = vim.fn.line(".")
  local loc_list = vim.fn.getloclist(0)
  table.remove(loc_list, loc_idx)
  vim.fn.setloclist(0, loc_list)
  -- Stay on the same line if possible, otherwise move up
  if loc_idx > #loc_list then
    loc_idx = #loc_list
  end
  if loc_idx > 0 then
    vim.cmd(tostring(loc_idx))
  end
end

--- Delete selected items from quickfix list (visual mode)
local function delete_qf_items_visual()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local qf_list = vim.fn.getqflist()

  -- Remove items in reverse order to maintain indices
  for i = end_line, start_line, -1 do
    table.remove(qf_list, i)
  end

  vim.fn.setqflist(qf_list)
  -- Move cursor to the line where deletion started
  vim.cmd(tostring(math.min(start_line, #qf_list)))
end

--- Delete selected items from location list (visual mode)
local function delete_loc_items_visual()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local loc_list = vim.fn.getloclist(0)

  -- Remove items in reverse order to maintain indices
  for i = end_line, start_line, -1 do
    table.remove(loc_list, i)
  end

  vim.fn.setloclist(0, loc_list)
  -- Move cursor to the line where deletion started
  vim.cmd(tostring(math.min(start_line, #loc_list)))
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
        vim.keymap.set("n", "dd", delete_loc_item, { buffer = bufnr, desc = "Delete location list item" })
        vim.keymap.set("x", "d", delete_loc_items_visual, { buffer = bufnr, desc = "Delete location list items" })
      else
        -- Quickfix list keymaps
        vim.keymap.set("n", "dd", delete_qf_item, { buffer = bufnr, desc = "Delete quickfix item" })
        vim.keymap.set("x", "d", delete_qf_items_visual, { buffer = bufnr, desc = "Delete quickfix items" })
      end
    end,
  })
end

return M
