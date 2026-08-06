# Plugin file layout and conventions

Layout depends on which loading pattern the file uses (see
`loading-patterns.md`).

## Eager (Pattern 1)

```lua
-- 1. Build hooks (must be registered BEFORE vim.pack.add)
vim.api.nvim_create_autocmd("PackChanged", { ... })

-- 2. Install + load
vim.pack.add(...)

-- 3. Setup
require("plugin").setup({ ... })

-- 4. Keymaps
vim.keymap.set(...)
```

## Deferred to VimEnter (Pattern 2)

```lua
-- 1. File-scope setup that doesn't need the plugin loaded (globals, etc.)
vim.g.some_flag = true

-- 2. Build hooks (must be registered BEFORE the deferred vim.pack.add fires)
vim.api.nvim_create_autocmd("PackChanged", { ... })

-- 3. Install + load + setup, all deferred
require("lazyload").on_vim_enter(function()
  vim.pack.add(...)
  require("plugin").setup({ ... })
end)

-- 4. Keymaps (file scope -- Neovim routes them to the plugin after load)
vim.keymap.set(...)
```

## Truly lazy (Pattern 3)

```lua
-- 1. Register on disk without loading
local packages = { { src = "...", name = "plugin-name" } }
vim.pack.add(packages, { load = function() end })

-- 2. First-use gate
local initialized = false
local function init()
  if initialized then return end
  initialized = true
  for _, p in ipairs(packages) do
    vim.cmd.packadd(p.name)
  end
  require("plugin").setup({ ... })
end

-- 3. Keymaps / commands / FileType autocmds call init() before first use
vim.keymap.set("n", "<leader>xx", function() init(); ... end, ...)
```

## Cross-plugin data sharing via `_G.Config`

Write to `_G.Config` at the **top level** of the producer file (outside
`on_vim_enter`), and read it inside the consumer's lazyload block. Top-level
assignments execute when Neovim sources `plugin/` files (step 11, before any
`VimEnter` callback runs), so the data is always available by the time lazyload
blocks fire:

```lua
-- plugin/producer.lua
_G.Config.some_data = { "foo", "bar" }
require("lazyload").on_vim_enter(function() ... end)

-- plugin/consumer.lua
require("lazyload").on_vim_enter(function()
  local some_data = _G.Config.some_data or {}
end)
```

## `do/end` blocks

Use them to scope locals and visually separate sections in long plugin files.
This keeps helpers from leaking into the rest of the file and makes boundaries
between logical sections obvious:

```lua
require("lazyload").on_vim_enter(function()
  local lint = require("lint")

  lint.linters_by_ft = { ... }

  -- protobuf linters
  do
    local cached_config = nil
    local function find_config() ... end
    vim.api.nvim_create_autocmd(...)
  end

  lint.try_lint()
end)
```

## Autogroups

Pass `{ clear = true }` to `nvim_create_augroup` -- it prevents duplicate
autocmds if the file is re-sourced.

## Per-filetype editor settings

Indent, wrap and conceal live in native `ftplugin/<ft>.lua` files, not in
`FileType` autocmds. `ftplugin/` is sourced by Neovim's built-in filetype
handling for **every** buffer of that filetype, including the first one opened —
a `FileType` autocmd registered inside an `on_vim_enter` callback runs too late
to catch the initial buffer.

```lua
-- ftplugin/templ.lua
vim.opt_local.expandtab = false
```

Before adding one, check whether Neovim's built-in ftplugin already sets what
you want (`:e $VIMRUNTIME/ftplugin/<ft>.vim`) — e.g. Go's `noexpandtab` and
Python's 4-space indent are already provided, so don't duplicate them. Custom
filetypes (registered with `vim.filetype.add` at the top level of a
`plugin/lang/<ft>.lua` file) get their own `ftplugin/<ft>.lua`.

## Option interfaces

Neovim exposes several Lua interfaces for setting options (`:h vim.o`, `:h
vim.opt`). This config uses **`vim.opt`** and **`vim.opt_local`** exclusively:

| Interface           | Equivalent to        | Notes                                                                |
| ------------------- | -------------------- | -------------------------------------------------------------------- |
| `vim.o`             | `:set`               | Raw string get/set -- no table support                               |
| `vim.bo`            | `:setlocal` (buffer) | Raw buffer-scoped options                                            |
| `vim.wo`            | `:setlocal` (window) | Raw window-scoped options                                            |
| `vim.go`            | `:setglobal`         | Global-only (skips local copy)                                       |
| **`vim.opt`**       | `:set`               | Rich `Option` object: tables, `:append()`, `:remove()`, `:prepend()` |
| **`vim.opt_local`** | `:setlocal`          | Same as `vim.opt` but buffer/window-local                            |

Use `vim.opt` in `init.lua` and `lua/options.lua`, `vim.opt_local` in
`ftplugin/<ft>.lua`. The only exception is `vim.wo[win][0]` for setting
window+buffer-scoped options on a specific window (e.g. LSP foldexpr override in
`LspAttach`).

## Adding a shared utility (toggle, custom picker, etc.)

1. Create `lua/<name>.lua` returning a module table
2. `require("<name>")` it from whatever `plugin/` file needs it

Example -- `lua/toggle.lua`:

```lua
local M = {}
function M.auto_format()
  vim.g.auto_format = not vim.g.auto_format
  vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
end
return M
```

Used in `plugin/conform.lua`:

```lua
vim.keymap.set("n", "<leader>uf", require("toggle").auto_format, { desc = "Toggle auto-format" })
```
