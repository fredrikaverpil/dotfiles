---
name: nvim-plugin
description:
  Guide for writing Neovim plugins in Lua following official Neovim conventions
  (https://neovim.io/doc/user/lua-plugin/). Use this skill whenever the user is
  creating, modifying, or reviewing a Neovim plugin — including when they
  mention plugin structure, ftplugin, health checks, keymaps, setup() functions,
  vimdoc, LuaCATS annotations, or lazy loading in the context of Neovim plugin
  development. Also trigger when the user is working in a directory that looks
  like a Neovim plugin (contains plugin/, lua/, ftplugin/ subdirectories).
---

# Writing Neovim Plugins

Reference: https://neovim.io/doc/user/lua-plugin/

## File Structure

A standard Neovim plugin layout:

```
myplugin.nvim/
├── plugin/
│   └── myplugin.lua      ← eagerly loaded at startup (keep minimal)
├── lua/
│   └── myplugin/
│       ├── init.lua      ← main module (required as 'myplugin')
│       ├── config.lua    ← option defaults + validation
│       └── health.lua    ← health checks (:checkhealth)
├── ftplugin/
│   └── rust.lua          ← filetype-specific init (optional)
├── doc/
│   └── myplugin.txt      ← vimdoc (generate with panvimdoc)
└── README.md
```

Neovim auto-discovers files in these paths — no registration needed.

## Lazy Loading

Keep `plugin/myplugin.lua` minimal. Defer `require()` into command/mapping
bodies, not at the top of the file. This preserves startup time.

```lua
-- BAD: eager load
local myplugin = require("myplugin")
vim.api.nvim_create_user_command("MyCommand", function()
  myplugin.run()
end, {})

-- GOOD: deferred load
vim.api.nvim_create_user_command("MyCommand", function()
  require("myplugin").run()
end, {})
```

## Keymapping Patterns

Avoid creating keymaps automatically — it conflicts with user config. Two
preferred approaches:

### `<Plug>` Mappings (recommended for simple actions)

```lua
-- In plugin/myplugin.lua
vim.keymap.set("n", "<Plug>(MyPluginAction)", function()
  require("myplugin").do_action()
end)
```

Users then bind it themselves:

```lua
vim.keymap.set("n", "<leader>a", "<Plug>(MyPluginAction)")
```

### Lua Functions (recommended for extensible actions)

```lua
-- Expose the function; let users decide the mapping
require("myplugin").do_action()  -- callable directly
```

For buffer-local mappings (custom UI, ftplugin), always pass `buffer = bufnr`:

```lua
vim.keymap.set("n", "<Plug>(MyPluginBufferAction)", function()
  require("myplugin").buffer_action()
end, { buffer = bufnr })
```

## Initialization: `setup()` Patterns

### Pattern 1: Separated config + init (preferred)

Plugin works out-of-the-box. `setup()` only overrides defaults — no `require()`
calls, side effects, or expensive work. Initialization happens in `plugin/` or
`ftplugin/` scripts, not inside `setup()`.

```lua
-- lua/myplugin/config.lua
local M = {}

M.defaults = {
  enabled = true,
  timeout = 500,
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M.validate()
end

function M.validate()
  vim.validate({
    enabled = { M.options.enabled, "boolean" },
    timeout = { M.options.timeout, "number" },
  })
end

return M
```

### Pattern 2: Combined `setup()` (use when init is complex/risky)

Requires the user to call `setup()` explicitly — even with defaults. Only choose
this when misconfiguration risk is high.

```lua
-- lua/myplugin/init.lua
local M = {}

function M.setup(opts)
  local config = require("myplugin.config")
  config.setup(opts)
  -- initialization logic here
  M._initialized = true
end

return M
```

## Guard Variables

Prevent re-initialization (e.g. from sourcing the same file twice):

```lua
-- plugin/myplugin.lua
if vim.g.loaded_myplugin then
  return
end
vim.g.loaded_myplugin = true
```

For ftplugin (per-buffer, not per-session):

```lua
-- ftplugin/rust.lua
local bufnr = vim.api.nvim_get_current_buf()
-- no session-level guard needed; ftplugin is intentionally per-buffer
```

**Set `filetype` as late as possible** in custom UI buffers so users can
override buffer-local settings via `FileType` autocmds.

## Health Checks

Create `lua/{plugin}/health.lua`. `:checkhealth {plugin}` auto-discovers it.

```lua
-- lua/myplugin/health.lua
local M = {}

function M.check()
  vim.health.start("myplugin")

  -- Check initialization
  local ok, config = pcall(require, "myplugin.config")
  if not ok then
    vim.health.error("myplugin not loaded")
    return
  end

  -- Check config
  if config.options.timeout < 100 then
    vim.health.warn("timeout < 100ms may cause issues")
  else
    vim.health.ok("configuration looks good")
  end

  -- Check external deps
  if vim.fn.executable("some-tool") == 1 then
    vim.health.ok("some-tool found")
  else
    vim.health.error("some-tool not found in PATH")
  end
end

return M
```

## Type Annotations (LuaCATS)

Annotate public APIs with LuaCATS for lua-language-server (luals):

```lua
---@class MyPlugin.Config
---@field enabled boolean
---@field timeout integer

---@param opts? MyPlugin.Config
function M.setup(opts) end

---@return MyPlugin.Config
function M.get_config() end
```

Integrate `lua-typecheck-action` in CI to catch type errors before users do.

## In-Process LSP Actions (advanced UI pattern)

For plugins with custom UIs, expose actions as LSP code-actions so users can
invoke them via standard `vim.lsp.buf.code_action()`:

```lua
-- Users can then filter and apply specific actions:
vim.lsp.buf.code_action({
  apply = true,
  filter = function(a)
    return a.title == "My Plugin Action"
  end,
})
```

## Versioning & Deprecation

- Follow **SemVer**: `MAJOR.MINOR.PATCH`
- Use `vim.deprecate()` when removing or renaming APIs:

```lua
function M.old_function(opts)
  vim.deprecate("myplugin.old_function", "myplugin.new_function", "2.0.0", "myplugin")
  return M.new_function(opts)
end
```

- Automate releases with `luarocks-tag-release` or `release-please-action`
- Publish to **luarocks** if the plugin has Lua dependencies or is itself a
  dependency

## Documentation (vimdoc)

Provide vimdoc so users can access `:h myplugin` in Neovim.

Generate from Markdown using `panvimdoc`, then regenerate help-tags:

```vim
:helptags doc/
```

## Development Workflow

- Use `:restart` to reload plugin changes during development
- Profile startup impact: `nvim --startuptime /tmp/nvim-startup.log`
- Add `dev = true` to your lazy.nvim spec to load from local path:

```lua
{
  "username/myplugin.nvim",
  dev = true,  -- loads from opts.dev.path/myplugin.nvim
}
```

## Code Style

Follow the project's Lua style (per `.stylua.toml`):

- 2-space indentation
- Double quotes
- 120 char line width
- Sort requires via `stylua`
