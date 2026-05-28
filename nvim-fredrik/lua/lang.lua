-- Per-language registry.
--
-- Each plugin/lang/<ft>.lua describes its own tooling via register() at the
-- TOP LEVEL of the file (outside on_vim_enter), so the call runs while plugin/
-- files are sourced — before any consumer reads the registry at VimEnter.
--
-- Consumers (plugin/lsp.lua, mason.lua, conform.lua, lint.lua) read the
-- aggregated values inside their own on_vim_enter blocks. File sourcing order
-- is therefore irrelevant: every register() has run by the time they read.
--
-- The registry only handles the flat lists. Tool *config* (formatter/linter
-- args, custom per-cwd autocmds) stays in the consumer files.

local M = {}

local registry = {}

---@class LangSpec
---@field servers? string[]                 lspconfig server names, e.g. "lua_ls"
---@field mason? string[]                    mason package names, e.g. "lua-language-server"
---@field formatters_by_ft? table<string, string[]>   conform formatters_by_ft entries
---@field formatters? table<string, table>  conform per-formatter config (args, etc.)
---@field linters_by_ft? table<string, string[]>      nvim-lint linters_by_ft entries
---@field linters? table<string, table>      nvim-lint per-linter config, merged into lint.linters
---@field lint_setup? fun(lint: table)       imperative lint wiring (autocmds, dynamic cwd)

--- Register a language's tooling. Call at the top level of plugin/lang/<ft>.lua.
---@param name string
---@param spec LangSpec
function M.register(name, spec)
  registry[name] = spec
end

---@param list string[]
---@return string[]
local function dedup(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  return out
end

--- Aggregated lspconfig server names across all registered languages.
---@return string[]
function M.servers()
  local out = {}
  for _, spec in pairs(registry) do
    vim.list_extend(out, spec.servers or {})
  end
  return dedup(out)
end

--- Aggregated mason package names across all registered languages.
---@param base? string[] cross-cutting tools not tied to a single language
---@return string[]
function M.mason_tools(base)
  local out = vim.list_extend({}, base or {})
  for _, spec in pairs(registry) do
    vim.list_extend(out, spec.mason or {})
  end
  return dedup(out)
end

--- Aggregated conform formatters_by_ft across all registered languages.
---@return table<string, string[]>
function M.formatters_by_ft()
  local out = {}
  for _, spec in pairs(registry) do
    for ft, tools in pairs(spec.formatters_by_ft or {}) do
      out[ft] = tools
    end
  end
  return out
end

--- Aggregated nvim-lint linters_by_ft across all registered languages.
---@return table<string, string[]>
function M.linters_by_ft()
  local out = {}
  for _, spec in pairs(registry) do
    for ft, tools in pairs(spec.linters_by_ft or {}) do
      out[ft] = tools
    end
  end
  return out
end

--- Aggregated conform per-formatter config across all registered languages.
---@return table<string, table>
function M.formatter_configs()
  local out = {}
  for _, spec in pairs(registry) do
    for name, cfg in pairs(spec.formatters or {}) do
      out[name] = cfg
    end
  end
  return out
end

--- Aggregated nvim-lint per-linter config across all registered languages.
---@return table<string, table>
function M.linter_configs()
  local out = {}
  for _, spec in pairs(registry) do
    for name, cfg in pairs(spec.linters or {}) do
      out[name] = cfg
    end
  end
  return out
end

--- Imperative lint_setup functions from all registered languages.
---@return fun(lint: table)[]
function M.lint_setups()
  local out = {}
  for _, spec in pairs(registry) do
    if spec.lint_setup then
      out[#out + 1] = spec.lint_setup
    end
  end
  return out
end

return M
