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

function M.setup_diagnostics()
  ---@class vim.diagnostic.Opts?
  local opts = {
    enable = true,

    virtual_lines = false,
    -- virtual_lines = {
    --   -- Only show virtual line diagnostics for the current cursor line
    --   current_line = false,
    -- },

    -- NOTE: disabled due to using the tiny-inline-diagnostic.nvim plugin
    virtual_text = false,
    -- virtual_text = function(_, _)
    --   ---@class vim.diagnostic.Opts.VirtualText
    --   return { spacing = 4, source = "if_many", prefix = prefix }
    -- end,

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

  vim.diagnostic.config(vim.deepcopy(opts))

  require("fredrik.config.keymaps").setup_diagnostics_keymaps()

  -- Set up quickfix/loclist editing keymaps
  require("fredrik.utils.quickfix").setup_qf_keymaps()
end

return M
