local M = {}

---@param diagnostic table
local function prefix(diagnostic)
  local icons = require("fredrik.utils.icons").icons.diagnostics
  for d, icon in pairs(icons) do
    if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
      return icon
    end
  end
end

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

function M.setup_diagnostics()
  ---@class vim.diagnostic.Opts?
  local opts = {
    enable = true,

    virtual_lines = false,
    -- virtual_lines = {
    --   -- Only show virtual line diagnostics for the current cursor line
    --   current_line = false,
    -- },

    -- virtual_text = false,
    virtual_text = function(_, _)
      ---@class vim.diagnostic.Opts.VirtualText
      return { spacing = 4, source = "if_many", prefix = prefix }
    end,

    underline = true,
    update_in_insert = false,
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = require("fredrik.utils.icons").icons.diagnostics.Error,
        [vim.diagnostic.severity.WARN] = require("fredrik.utils.icons").icons.diagnostics.Warn,
        [vim.diagnostic.severity.HINT] = require("fredrik.utils.icons").icons.diagnostics.Hint,
        [vim.diagnostic.severity.INFO] = require("fredrik.utils.icons").icons.diagnostics.Info,
      },
    },
  }

  -- set diagnostic icons
  for name, icon in pairs(require("fredrik.utils.icons").icons.diagnostics) do
    name = "DiagnosticSign" .. name
    vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
  end

  -- NOTE: disabled due to using the tiny-inline-diagnostic.nvim plugin
  -- vim.diagnostic.config(vim.deepcopy(opts))

  require("fredrik.config.keymaps").setup_diagnostics_keymaps()
end

return M
