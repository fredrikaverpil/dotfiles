---
name: nvim-config
description: >
  Native Neovim config idioms and conventions — use whenever writing, reviewing,
  or modifying any Neovim configuration that uses Neovim's built-in conventions
  WITHOUT a plugin manager framework (no lazy.nvim, packer, etc.). Covers
  directory structure, vim.pack plugin management, lsp/ auto-discovery, plugin/
  loading order, ftplugin/, keymaps, and standard paths. Trigger on any task
  involving init.lua, plugin/*.lua, lsp/*.lua, ftplugin/*.lua, vim.pack.add(),
  vim.lsp.enable(), or "native neovim config" — even if the user just says
  "add a plugin" or "configure LSP" in a native-style config.
---

# Native Neovim Config

Reference for Neovim configs using built-in conventions (vim.pack, lsp/,
plugin/, ftplugin/) without a plugin manager framework. Requires Neovim ≥
v0.12.0 (nightly).

## This config's location

The native config lives at **`~/.dotfiles/nvim-native/`** inside the dotfiles
repo. It is symlinked into place via GNU Stow:

```
~/.dotfiles/nvim-native/          ← actual files (edit here)
~/.dotfiles/stow/shared/.config/nvim-native → ../../../nvim-native  (stow entry)
~/.config/nvim-native → ~/.dotfiles/stow/shared/.config/nvim-native  (stow result)
```

To launch this config:

```sh
NVIM_APPNAME=nvim-native nvim
```

The dotfiles repo also contains a lazy.nvim-based config at
`~/.dotfiles/nvim-fredrik/` (launched with `NVIM_APPNAME=nvim-fredrik nvim`).

To apply stow symlinks after changes: `./rebuild.sh --stow` from `~/.dotfiles/`.
Neovim itself is managed by [Bob](https://github.com/MordechaiHadad/bob), not
nixpkgs — binary at `~/.local/share/bob/nvim-bin/nvim`.

## Documentation

**Local disk** — docs ship with Neovim at `$VIMRUNTIME/doc/`. With Bob-managed
nightly the path is `~/.local/share/bob/nightly/share/nvim/runtime/doc/`. Read
them with `:h <tag>` inside Neovim or directly with your editor/pager.

Key help files for native config work:

| Topic | Help tag | File |
|-------|----------|------|
| Startup & init order | `:h initialization` | `starting.txt` |
| Native package manager | `:h vim.pack` | `pack.txt` |
| packages / packpath | `:h packages` | `pack.txt` |
| LSP config auto-discovery | `:h lsp-config` | `lsp.txt` |
| Enable/disable servers | `:h vim.lsp.enable()` | `lsp.txt` |
| ftplugin directory | `:h ftplugin` | `usr_41.txt` |
| after/ directory | `:h after-directory` | `options.txt` |
| runtimepath | `:h runtimepath` | `options.txt` |
| autoload/ | `:h autoload` | `userfunc.txt` |
| colors/ | `:h colorscheme` | `syntax.txt` |

**Online** — https://neovim.io/doc/user/ (mirrors the same help pages).
Searching the web for `:h <tag>` plus "neovim" also works well.

---

## Runtime directories and load order

Neovim searches these directories in every runtimepath entry
(`:h 'runtimepath'`). Each directory has a specific purpose and timing:

| Directory | When | Purpose |
|---|---|---|
| `init.lua` | Once, first | Leader keys, `require("options")`, diagnostics |
| `lua/` | On `require()` | Lua modules (never auto-sourced) |
| `plugin/**/*.lua` | Once, at startup | Plugin install + setup (alphabetical, subdirs included) |
| `ftplugin/<ft>.lua` | Per-buffer, on FileType | Buffer-local settings (`vim.opt_local`) |
| `indent/<ft>.lua` | Per-buffer, on FileType | Indent expressions |
| `syntax/<ft>.vim` | Per-buffer, on FileType | Legacy syntax highlighting (treesitter overrides) |
| `lsp/<server>.lua` | Startup (discovery) | LSP config tables, auto-discovered by `vim.lsp.config` |
| `parser/<lang>.so` | On demand | Treesitter parsers |
| `queries/<lang>/*.scm` | On demand | Treesitter queries (highlights, injections, folds, indents) |
| `colors/<name>.{vim,lua}` | On demand | Colorschemes, loaded by `:colorscheme` |
| `autoload/` | On first call | Auto-loaded Vimscript/Lua functions |
| `compiler/` | On `:compiler` | Compiler settings |
| `spell/` | On demand | Spell checking files |

### after/ directory

**Any** of the above directories can also exist under `after/`. The `after/`
tree is a full runtimepath entry that loads *after* all non-after paths, so
its files always win. Docs: `:h after-directory`

The load order repeats with `after/` — for example:

```
1. plugin/**/*.lua            ← runs first
2. after/plugin/**/*.lua      ← runs after all plugin/ files

3. ftplugin/<ft>.lua          ← runs on FileType
4. after/ftplugin/<ft>.lua    ← runs after, overrides the above

5. syntax/<ft>.vim            ← runs on FileType
6. after/syntax/<ft>.vim      ← runs after, extends/overrides

7. queries/<lang>/*.scm       ← base queries
8. after/queries/<lang>/*.scm ← extends (with `; extends` modeline)

9. lsp/<server>.lua           ← base config
10. after/lsp/<server>.lua    ← overrides fields from the base config
```

### Notes

- `ftplugin/go.lua` fires **every time you open a `.go` file**, not at startup.
  Use it for `vim.opt_local.*` — not for plugin config.
- The `LspAttach` autocmd (in whichever `plugin/` file sets it up) bridges
  startup and per-buffer: keymaps are registered per-buffer when the LSP server
  attaches, even though the autocmd itself is registered once at startup.

---

## Architecture: layers and their roles

This config has no framework — each directory has a single responsibility:

| Layer | Directory | Role |
|---|---|---|
| **options** | `lua/options.lua` | All `vim.opt` settings, required from `init.lua` |
| **utility** | `lua/` | Shared Lua modules, `require()`'d explicitly (fold helpers, toggle, pickers) |
| **wiring** | `plugin/` | Plugin install + setup + keymaps. Self-contained per plugin. |
| **lang extensions** | `after/plugin/lang/` | Per-language formatter/linter config. Extends `plugin/` files. |
| **server config** | `lsp/` | LSP server config tables, auto-discovered by `vim.lsp.config` |
| **editor settings** | `ftplugin/` | Per-filetype `vim.opt_local` settings (indent, wrap, etc.) |

**Key rule:** `plugin/` files set up plugin infrastructure (empty `formatters_by_ft`, empty `linters_by_ft`). Language specifics go in `after/plugin/lang/` — guaranteed to run after all `plugin/` files, so no `pcall` or ordering tricks needed.

---

## Directory structure

Conceptual layout (`:h initialization`, step 11 uses `plugin/**/*.{vim,lua}` — **subdirectories included**):

```
~/.config/nvim-native/
  init.lua               — leader keys, require("options"), diagnostics
  lua/                   — Lua modules loaded via require()
  lsp/                   — one file per LSP server; auto-discovered
  parser/                — treesitter parser .so files (managed by nvim-treesitter)
  colors/                — custom colorschemes (loaded by :colorscheme)
  plugin/
    core/                — foundation plugins (completion, LSP, format, lint, UI)
    <name>.lua           — other plugins
  after/
    plugin/
      lang/              — one file per filetype; extends core plugin tables
    lsp/                 — overrides for LSP configs from packages
    queries/<lang>/      — treesitter query extensions (injections.scm, etc.)
    syntax/<ft>.vim       — legacy syntax overrides/extensions
  ftplugin/              — per-filetype editor settings (vim.opt_local only)
```

**`init.lua`** — Minimal entrypoint: leader keys, `require("options")`,
diagnostics config. Docs: `:h initialization`

**`lua/`** — Lua modules loaded via `require()`. Never auto-sourced.
Includes `options.lua` (editor options, required from `init.lua`),
`fold.lua` (fold helpers shared by `init.lua` and `plugin/core/lsp.lua`),
and any other shared utilities (toggle helpers, custom pickers, etc.).

**`plugin/`** — Each file is self-contained: `vim.pack.add()` at the top,
`setup()` below it, keymaps inline. Sourced alphabetically; subdirectories
included via the `**` glob. Docs: `:h initialization` (step 11)

**`plugin/core/`** — Foundation plugins: completion, formatting, linting, LSP
wiring, tool installer (mason), statusline, notifications/picker. Organizational
convention — not a load-order guarantee (see decision guide below).

**`after/plugin/lang/`** — One file per filetype. Extends `formatters_by_ft`,
`linters_by_ft`, and other tables owned by `plugin/core/` files. Runs after all
`plugin/` files — no `pcall` or ordering hacks needed.
Docs: `:h after-directory`

**`lsp/`** — Each file returns a `vim.lsp.Config` table; filename becomes the
server name. No `setup()` call needed. Enable servers explicitly elsewhere
(`vim.lsp.enable(...)`). Docs: `:h lsp-config`

**`ftplugin/`** — Sourced when a buffer's filetype is set. For
`vim.opt_local.*` only — not for plugin config. No `autocmd FileType` needed.
Docs: `:h ftplugin`

---

## vim.pack — built-in plugin management

```lua
-- Install (if missing) and load plugins. Code is available immediately after.
vim.pack.add({
  "https://github.com/user/repo",                                    -- string form
  { src = "https://github.com/user/repo" },                          -- table form
  { src = "https://github.com/user/repo", name = "repo" },           -- custom name
  { src = "https://github.com/user/repo", version = "main" },                   -- branch/tag/commit
  { src = "https://github.com/user/repo", version = vim.version.range("1.*") }, -- semver range
})
```

- **`load` option**: during `init.lua`/`plugin/` sourcing, defaults to `false`
  (`:packadd!` — available but `plugin/` files of the installed plugin not yet
  sourced). After startup, defaults to `true`. Pass `load = true` explicitly if
  you need a plugin's `plugin/` files sourced immediately.
- **Install location**: `stdpath("data") .. "/site/pack/core/opt/<name>"`
- **Lockfile**: `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json` — commit to VCS
  for reproducible installs across machines.

```lua
vim.pack.update()               -- interactive update with confirmation buffer
vim.pack.update({"name"}, { force = true })   -- update specific plugin, skip confirm
vim.pack.del({"name"})          -- remove from disk
vim.pack.get()                  -- list all managed plugins
```

**No URL shorthand helpers** in this config. The upstream docs suggest
`local gh = function(x) ... end` but since we scatter `vim.pack.add()` across
many `plugin/` files (one per plugin), a central helper adds no value. Use full
URLs directly.

---

## lsp/ config files

Each file returns a `vim.lsp.Config` table. The filename (without `.lua`)
becomes the server name.

```lua
-- lsp/gopls.lua
---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
}
```

Enable servers from `plugin/lsp.lua` (not from `lsp/` files themselves):

```lua
vim.lsp.enable({ "gopls", "lua_ls" })
```

To disable a server: `vim.lsp.enable("gopls", false)`.

---

## plugin/ vs after/plugin/ — decision guide

Default: **everything goes in `plugin/`**. Most plugins are order-independent
— they install, set up, and register autocmds that fire later. No ordering needed.

Move something to `after/plugin/` only when it has a **concrete, named
dependency** on a `plugin/` file being fully done:

| Situation | Where |
|---|---|
| Installing and setting up a foundation plugin | `plugin/core/<name>.lua` |
| Installing and setting up any other plugin | `plugin/<name>.lua` |
| Extending `formatters_by_ft` / `linters_by_ft` | `after/plugin/lang/<ft>.lua` |
| Any file that mutates tables owned by a `plugin/` file | `after/plugin/` |

### plugin/core/ — foundation plugins

`plugin/core/` holds the structural foundation: completion, formatting, linting,
LSP wiring, tool installer (mason), statusline, notifications/picker.
Everything else lives directly in `plugin/`.

This is an **organizational convention**, not a load-order guarantee. Files sort
lexicographically across the full `plugin/**` expansion — `core/` happens to sort
early, but don't rely on it. Both subdirectories run at startup and are
order-independent by design (event-driven via autocmds).

### Within plugin/ — ordering

Files are sourced in ASCII sort order. Most autocmds (`LspAttach`,
`BufWinEnter`) fire after all `plugin/` files are sourced, so event-driven
code resolves dependencies naturally.

Numeric prefixes are a last resort for within-`plugin/` ordering only — prefer
`after/plugin/` when the dependency crosses the plugin/after boundary:

```
plugin/
  01_mason.lua     -- only if mason must be ready before other plugin/ files
  02_lsp.lua
```

---

## Key idioms

**Self-contained plugin file** (the standard pattern):

```lua
-- plugin/conform.lua
vim.pack.add({
  { src = "https://github.com/stevearc/conform.nvim" },
})

vim.g.auto_format = true

require("conform").setup({
  formatters_by_ft = { go = { "gofumpt", "goimports" } },
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("native-conform", { clear = true }),
  callback = function(args)
    if vim.g.auto_format then
      require("conform").format({ bufnr = args.buf, timeout_ms = 5000 })
    end
  end,
})

vim.keymap.set("n", "<leader>tf", function()
  vim.g.auto_format = not vim.g.auto_format
  vim.notify("Auto-format: " .. (vim.g.auto_format and "on" or "off"))
end, { desc = "Toggle auto-format" })
```

**Always** pass `{ clear = true }` to `nvim_create_augroup` — prevents
duplicate autocmds if the file is re-sourced.

**ftplugin** for per-filetype settings, not autocmds:

```lua
-- ftplugin/go.lua
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = false
```

---

## Option interfaces

Neovim exposes several Lua interfaces for setting options (`:h vim.o`,
`:h vim.opt`). This config uses **`vim.opt`** and **`vim.opt_local`**
exclusively:

| Interface | Equivalent to | Notes |
|---|---|---|
| `vim.o` | `:set` | Raw string get/set — no table support |
| `vim.bo` | `:setlocal` (buffer) | Raw buffer-scoped options |
| `vim.wo` | `:setlocal` (window) | Raw window-scoped options |
| `vim.go` | `:setglobal` | Global-only (skips local copy) |
| **`vim.opt`** | `:set` | Rich `Option` object: tables, `:append()`, `:remove()`, `:prepend()` |
| **`vim.opt_local`** | `:setlocal` | Same as `vim.opt` but buffer/window-local |

**Convention:** use `vim.opt` in `init.lua` and `plugin/` files, use
`vim.opt_local` in `ftplugin/` files. The only exception is `vim.wo[win][0]`
for setting window+buffer-scoped options on a specific window (e.g. LSP
foldexpr override in `LspAttach`).

---

## Standard paths

| Purpose | Lua | Typical path |
|---------|-----|-------------|
| Config dir | `vim.fn.stdpath("config")` | `~/.config/nvim` |
| Data dir | `vim.fn.stdpath("data")` | `~/.local/share/nvim` |
| Plugin install | `stdpath("data") .. "/site/pack/core/opt/"` | — |
| State dir | `vim.fn.stdpath("state")` | `~/.local/state/nvim` |
| Runtime | `vim.fn.expand("$VIMRUNTIME")` | `.../share/nvim/runtime` |
| Cache | `vim.fn.stdpath("cache")` | `~/.cache/nvim` |

With `NVIM_APPNAME=nvim-native`, paths use `nvim-native` instead of `nvim`.

---

## Adding a new language

1. `lsp/<server>.lua` — return the server config table
2. `plugin/lsp.lua` — add server name to `vim.lsp.enable({})`
3. `plugin/mason.lua` — add tool names to `ensure_installed`
4. `after/plugin/lang/<ft>.lua` — extend conform/lint for this filetype:
   ```lua
   require("conform").setup({ formatters_by_ft = { python = { "ruff_format" } } })
   require("lint").linters_by_ft.python = { "ruff" }
   ```
5. `ftplugin/<ft>.lua` — editor settings only (`vim.opt_local.*`)

Do **not** add language-specific formatter or linter config to `plugin/conform.lua`
or `plugin/lint.lua` — those files own infrastructure only.

## Adding a shared utility (toggle, custom picker, etc.)

1. Create `lua/<name>.lua` returning a module table
2. `require("<name>")` it from whatever `plugin/` file needs it

Example — `lua/toggle.lua`:
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
vim.keymap.set("n", "<leader>tf", require("toggle").auto_format, { desc = "Toggle auto-format" })
```
