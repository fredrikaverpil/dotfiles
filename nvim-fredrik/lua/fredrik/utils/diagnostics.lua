M = {}

function M.setup_diagnostics()
  local diagnostics = {
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
      -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
      -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
      -- prefix = "icons",
    },
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

  local version = require("fredrik.utils.version")
  if type(diagnostics.virtual_text) == "table" and diagnostics.virtual_text.prefix == "icons" then
    diagnostics.virtual_text.prefix = version.is_neovim_0_10_0() == 0 and "●"
        or function(diagnostic)
          local icons = require("fredrik.utils.icons").icons.diagnostics
          for d, icon in pairs(icons) do
            if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
              return icon
            end
          end
        end
  end

  vim.diagnostic.config(vim.deepcopy(diagnostics))

  require("fredrik.config.keymaps").setup_diagnostics_keymaps()
end

return M
