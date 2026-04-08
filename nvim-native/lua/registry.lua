---@class RegistryLintOpts
---@field linters_by_ft? table<string, string[]>
---@field linters? table<string, lint.Linter>

---@class RegistryDapOpts
---@field adapters? table<string, any>
---@field configurations? table<string, any[]>
---@field setups? fun()[]

---@class RegistryNeotestAdapter
---@field module string
---@field opts? table

---@class RegistryNeotestOpts
---@field adapters? RegistryNeotestAdapter[]

---@class RegistryLualineOpts
---@field lualine_a? table[]
---@field lualine_b? table[]
---@field lualine_c? table[]
---@field lualine_x? table[]
---@field lualine_y? table[]
---@field lualine_z? table[]

---@class RegistrySpec
---@field lsp_servers? string[]
---@field mason_tools? string[]
---@field conform? conform.setupOpts
---@field lint? RegistryLintOpts
---@field blink? blink.cmp.Config
---@field code_runner? table<string, string[]>
---@field dap? RegistryDapOpts
---@field neotest? RegistryNeotestOpts
---@field lualine? RegistryLualineOpts

---@class Registry
---@field lsp_servers string[]
---@field mason_tools string[]
---@field conform conform.setupOpts
---@field lint RegistryLintOpts
---@field blink blink.cmp.Config
---@field code_runner table<string, string[]>
---@field dap RegistryDapOpts
---@field neotest RegistryNeotestOpts
---@field lualine RegistryLualineOpts
local M = {
  lsp_servers = {},
  mason_tools = {},
  conform = {},
  lint = { linters_by_ft = {}, linters = {} },
  blink = {},
  code_runner = {},
  dap = { adapters = {}, configurations = {}, setups = {} },
  neotest = { adapters = {} },
  lualine = {},
}

---@param spec RegistrySpec
function M.add(spec)
  if spec.lsp_servers then
    vim.list_extend(M.lsp_servers, spec.lsp_servers)
  end
  if spec.mason_tools then
    vim.list_extend(M.mason_tools, spec.mason_tools)
  end
  if spec.conform then
    M.conform = vim.tbl_deep_extend("force", M.conform, spec.conform)
  end
  if spec.lint then
    M.lint = vim.tbl_deep_extend("force", M.lint, spec.lint)
  end
  if spec.blink then
    M.blink = vim.tbl_deep_extend("force", M.blink, spec.blink)
  end
  if spec.code_runner then
    M.code_runner = vim.tbl_deep_extend("force", M.code_runner, spec.code_runner)
  end
  if spec.dap then
    if spec.dap.adapters then
      M.dap.adapters = vim.tbl_deep_extend("force", M.dap.adapters, spec.dap.adapters)
    end
    if spec.dap.configurations then
      M.dap.configurations = vim.tbl_deep_extend("force", M.dap.configurations, spec.dap.configurations)
    end
    if spec.dap.setups then
      vim.list_extend(M.dap.setups, spec.dap.setups)
    end
  end
  if spec.neotest then
    if spec.neotest.adapters then
      vim.list_extend(M.neotest.adapters, spec.neotest.adapters)
    end
  end
  if spec.lualine then
    for section, components in pairs(spec.lualine) do
      M.lualine[section] = M.lualine[section] or {}
      vim.list_extend(M.lualine[section], components)
    end
  end
end

return M
