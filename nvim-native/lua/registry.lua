local merge = require("merge")

---@class RegistrySpec
---@field blink? blink.cmp.Config
---@field code_runner? table
---@field conform? conform.setupOpts
---@field dap? { adapters?: table<string, dap.Adapter|fun(callback: fun(adapter: dap.Adapter), config: dap.Configuration)>, configurations?: table<string, dap.Configuration[]>, setups?: fun()[] }
---@field lint? table
---@field lsp_servers? string[]
---@field lualine? table
---@field mason? MasonSettings
---@field mason_ensure_installed? string[]
---@field mason_pip_extra_packages? table<string, string[]>
---@field neotest? neotest.Config
local M = {
  blink = {},
  code_runner = {},
  conform = {},
  dap = {},
  lint = {},
  lsp_servers = {},
  lualine = {},
  mason = {},
  mason_ensure_installed = {},
  mason_pip_extra_packages = {},
  neotest = {},
}

---@param spec RegistrySpec
function M.add(spec)
  merge(M, spec)
end

return M
