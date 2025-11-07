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
          vim.api.nvim_del_augroup_by_name("DiagnosticListAutoUpdate")
        end,
      })
    end,
  })
end

--- Open buffer diagnostics in location list with auto-update
function M.open_loclist()
  local diagnostics = vim.diagnostic.get(0)
  local items = M.diagnostics_to_qf_items(diagnostics)
  vim.fn.setloclist(0, items)
  vim.cmd("lopen")
  setup_auto_update("loclist", vim.api.nvim_get_current_buf())
end

--- Open workspace diagnostics in quickfix list with auto-update
function M.open_qflist()
  local diagnostics = vim.diagnostic.get()
  local items = M.diagnostics_to_qf_items(diagnostics)
  vim.fn.setqflist(items)
  vim.cmd("copen")
  setup_auto_update("qflist", nil)
end

return M
