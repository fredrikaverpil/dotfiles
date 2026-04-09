local merge = require("merge")

---@class RegistrySpec
---@field lsp? { servers?: string[] }
---@field mason? { opts?: MasonSettings, ensure_installed?: string[], pip_extra_packages?: table<string, string[]> }
---@field conform? { opts?: conform.setupOpts }
---@field lint? { linters_by_ft?: table<string, string[]>, linters?: table<string, lint.Linter> }
---@field blink? { opts?: blink.cmp.Config }
---@field code_runner? { opts?: table }
---@field dap? { adapters?: table<string, dap.Adapter|fun(callback: fun(adapter: dap.Adapter), config: dap.Configuration)>, configurations?: table<string, dap.Configuration[]>, setups?: fun()[] }
---@field neotest? { opts?: neotest.Config }
---@field lualine? { opts?: table, sections?: table<string, table> }
local M = {
  lsp = {},
  mason = {},
  conform = {},
  lint = {},
  blink = {},
  code_runner = {},
  dap = {},
  neotest = {},
  lualine = {},
}

---@param spec RegistrySpec
function M.add(spec)
  merge(M, spec)
end

return M
