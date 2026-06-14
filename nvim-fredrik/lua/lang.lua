-- Per-language registry.
--
-- Each plugin/lang/<ft>.lua (or a project .nvim.lua) describes its own tooling
-- via register() at the TOP LEVEL of the file (outside on_vim_enter), so the
-- call runs while plugin/ files are sourced — before any consumer reads the
-- registry at VimEnter.
--
-- Consumers (plugin/lsp.lua, mason.lua, conform.lua, lint.lua, neotest.lua,
-- dap.lua) call spec() inside their own on_vim_enter blocks and read the field
-- they consume. File
-- sourcing order is therefore irrelevant: every register() has run by the
-- time spec() is called.
--
-- There is only one vocabulary: the LangSpec field names, which mirror the
-- consumer's own option names where one exists (conform's formatters_by_ft /
-- formatters, nvim-lint's linters_by_ft / linters).

local M = {}

local registry = {}

---@class LangSpec
---@field servers? string[]                  lspconfig server names, e.g. "lua_ls"
---@field mason? string[]                    mason package names, e.g. "lua-language-server"
---@field mason_pip? table<string, string[]> extra pip packages installed into a mason pypi package's venv
---@field formatters_by_ft? table<string, string[]>   conform formatters_by_ft entries
---@field formatters? table<string, table>  conform per-formatter config (args, etc.)
---@field linters_by_ft? table<string, string[]>      nvim-lint linters_by_ft entries
---@field linters? table<string, table>      nvim-lint per-linter config, merged into lint.linters
---@field lint_setup? fun(lint: table)       imperative lint wiring (autocmds, dynamic cwd)
---@field neotest? { packs?: table[], adapter: fun(): table }  neotest adapter plugin packs + a builder returning the adapter
---@field dap? { packs?: table[], setup: fun(dap: table) }  dap adapter plugin packs + an imperative setup hook receiving the dap module

-- Keyed-table fields that spec() merges with "last write wins". The registry
-- is iterated with pairs(), which has no defined order, so a key registered by
-- two languages would be resolved by coin flip — treat it as a config error.
local keyed_fields = { "formatters_by_ft", "formatters", "linters_by_ft", "linters" }

--- Register a language's tooling. Call at the top level of plugin/lang/<ft>.lua.
--- Re-registering the same name replaces the previous spec. A keyed entry
--- (e.g. formatters_by_ft.markdown) already claimed by another language warns:
--- own the key in one place, or patch via lazyload.on_override instead.
---@param name string
---@param spec LangSpec
function M.register(name, spec)
  for other_name, other in pairs(registry) do
    if other_name ~= name then
      for _, field in ipairs(keyed_fields) do
        for key in pairs(spec[field] or {}) do
          if (other[field] or {})[key] ~= nil then
            vim.notify(
              ("lang: %s.%s[%q] is already registered by %s — merge order is undefined"):format(
                name,
                field,
                key,
                other_name
              ),
              vim.log.levels.WARN
            )
          end
        end
      end
    end
  end
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

--- The merged LangSpec across all registered languages. Lists are
--- concatenated and deduplicated; keyed tables merge per key (last write
--- wins); lint_setup functions are collected into a list. The neotest and dap
--- fields each group every language's adapter packs (concatenated) and hooks
--- (collected into a list) so the consumer can batch-add the packs, then build
--- all adapters for neotest's single setup() / run each dap setup hook.
---@class MergedLangSpec
---@field servers string[]
---@field mason string[]
---@field mason_pip table<string, string[]>
---@field formatters_by_ft table<string, string[]>
---@field formatters table<string, table>
---@field linters_by_ft table<string, string[]>
---@field linters table<string, table>
---@field lint_setup (fun(lint: table))[]
---@field neotest { packs: table[], adapters: (fun(): table)[] }
---@field dap { packs: table[], setups: (fun(dap: table))[] }

---@return MergedLangSpec
function M.spec()
  local out = {
    servers = {},
    mason = {},
    mason_pip = {},
    formatters_by_ft = {},
    formatters = {},
    linters_by_ft = {},
    linters = {},
    lint_setup = {},
    neotest = { packs = {}, adapters = {} },
    dap = { packs = {}, setups = {} },
  }
  for _, spec in pairs(registry) do
    vim.list_extend(out.servers, spec.servers or {})
    vim.list_extend(out.mason, spec.mason or {})
    for pkg, packages in pairs(spec.mason_pip or {}) do
      out.mason_pip[pkg] = dedup(vim.list_extend(out.mason_pip[pkg] or {}, packages))
    end
    for ft, tools in pairs(spec.formatters_by_ft or {}) do
      out.formatters_by_ft[ft] = tools
    end
    for name, cfg in pairs(spec.formatters or {}) do
      out.formatters[name] = cfg
    end
    for ft, tools in pairs(spec.linters_by_ft or {}) do
      out.linters_by_ft[ft] = tools
    end
    for name, cfg in pairs(spec.linters or {}) do
      out.linters[name] = cfg
    end
    if spec.lint_setup then
      out.lint_setup[#out.lint_setup + 1] = spec.lint_setup
    end
    if spec.neotest then
      vim.list_extend(out.neotest.packs, spec.neotest.packs or {})
      if spec.neotest.adapter then
        out.neotest.adapters[#out.neotest.adapters + 1] = spec.neotest.adapter
      end
    end
    if spec.dap then
      vim.list_extend(out.dap.packs, spec.dap.packs or {})
      if spec.dap.setup then
        out.dap.setups[#out.dap.setups + 1] = spec.dap.setup
      end
    end
  end
  out.servers = dedup(out.servers)
  out.mason = dedup(out.mason)
  return out
end

return M
