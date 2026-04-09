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

## Startup sequence (`:h initialization`)

The complete Neovim startup sequence, from `:h initialization`:

| Step | What happens |
|------|-------------|
| 1 | Set `'shell'` from `$SHELL` |
| 2 | Process arguments, execute `--cmd` args, create buffers (not loaded yet) |
| 3 | Start server, set `v:servername` |
| 4 | Wait for UI to connect (if `--embed`) |
| 5 | Setup default mappings and autocmds |
| 6 | Enable filetype and indent plugins (`:runtime! ftplugin.vim indent.vim`) |
| **7a** | System vimrc (`sysinit.vim`) |
| **7b** | **User config (`init.lua`)** — leader keys, `require("options")`, etc. |
| **7c** | **`.nvim.lua` (exrc)** — project-local config, if `'exrc'` is on |
| 8 | Enable filetype detection (`:runtime! filetype.lua`) |
| 9 | Enable syntax highlighting |
| 10 | Set `v:vim_did_init = 1` |
| **11** | **Load plugins**: `plugin/**/*.lua`, then packages, then `after/` plugins |
| 12 | Set `'shellpipe'` and `'shellredir'` |
| 13 | Set `'updatecount'` to zero if `-n` was given |
| 14 | Set binary options if `-b` was given |
| 15 | Read ShaDa file |
| 16 | Read quickfix file if `-q` was given |
| 17 | Open windows, load buffers → triggers **`VimEnter`**, then **`UIEnter`** |

**Key takeaway:** All `plugin/` files run at step 11. `VimEnter` (step 17)
fires **after** everything — this is when deferred setup functions run via
`defer.on_vim_enter()`. `UIEnter` fires after `VimEnter` and is used for
heavier setup (LSP, blink, treesitter).

---

## Runtime directories

Neovim searches these directories in every runtimepath entry
(`:h 'runtimepath'`). Each directory has a specific purpose and timing:

| Directory | When | Purpose |
|---|---|---|
| `init.lua` | Step 7b, once | Leader keys, `require("options")`, diagnostics |
| `lua/` | On `require()` | Lua modules (never auto-sourced) |
| `plugin/**/*.lua` | Step 11, once | Plugin install + setup (alphabetical, subdirs included) |
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

The `after/` tree loads *after* all non-after paths. This config only uses
`after/lsp/` for extending LSP server configs (e.g. `after/lsp/gopls.lua`
adds templ/gotmpl filetypes to the base gopls config). Docs: `:h after-directory`

### Per-project overrides (exrc)

With `vim.opt.exrc = true` (set in `lua/options.lua`), Neovim sources
`.nvim.lua` from the current working directory at **step 7c** — **before**
`plugin/` files (step 11), and before filetype detection (step 8). This is
the native equivalent of lazy.nvim's `.lazy.lua`.
Docs: `:h exrc`, `:h initialization`

Because `.nvim.lua` runs before plugins, direct `require("conform").setup()`
calls will be overwritten by plugin setup at VimEnter. To override plugin
config per-project, wrap the call in a `VimEnter` autocmd:

```lua
-- .nvim.lua (project root)
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("conform").setup({
      formatters_by_ft = { markdown = { "mdformat" } },
    })
  end,
})
```

### Notes

- `ftplugin/go.lua` fires **every time you open a `.go` file**, not at startup.
  Use it for `vim.opt_local.*` — not for plugin config.
- The `LspAttach` autocmd (in the lsp.lua plugin file) bridges startup and
  per-buffer: keymaps are registered per-buffer when the LSP server attaches,
  even though the autocmd itself is registered once at startup.

---

## Architecture: layers and their roles

This config has no framework — each directory has a single responsibility:

| Layer | Directory | Role |
|---|---|---|
| **options** | `lua/options.lua` | All `vim.opt` settings, required from `init.lua` |
| **utility** | `lua/` | Shared Lua modules: `merge.lua`, `defer.lua`, `fold.lua`, `toggle.lua`, pickers, etc. |
| **registry** | `lua/registry.lua` | Central typed registry — lang files declare, consumers read |
| **wiring** | `plugin/` | Plugin install + setup + keymaps. Self-contained per plugin. |
| **lang declarations** | `plugin/lang/` | Per-language requirements (LSP, mason, formatters, linters) via registry |
| **consumers** | `plugin/` | Read registry at VimEnter/UIEnter via `defer`, call setup() |
| **server config** | `lsp/` | LSP server config tables, auto-discovered by `vim.lsp.config` |
| **server overrides** | `after/lsp/` | Extend base LSP configs (e.g. gopls + templ/gotmpl) |
| **editor settings** | `ftplugin/` | Per-filetype `vim.opt_local` settings (indent, wrap, etc.) |

**Key rule:** `plugin/lang/` files **declare** requirements into the registry
(immediate). Consumer plugins **read** from the registry in deferred callbacks
(VimEnter/UIEnter). The `defer.lua` module guarantees all data is registered
before any consumer reads it.

---

## Directory structure

Conceptual layout (`:h initialization`, step 11 uses `plugin/**/*.{vim,lua}` — **subdirectories included**):

```
~/.config/nvim-native/
  init.lua               — leader keys, require("options"), diagnostics
  lua/
    registry.lua         — central registry (lang files declare, consumers read)
    merge.lua            — deep merge helper (appends+deduplicates lists, recurses dicts)
    defer.lua            — VimEnter/UIEnter deferred setup queues
    options.lua          — all vim.opt settings
    ...                  — other utility modules (fold, toggle, pickers, etc.)
  lsp/                   — one file per LSP server; auto-discovered
  parser/                — treesitter parser .so files (managed by nvim-treesitter)
  colors/                — custom colorschemes (loaded by :colorscheme)
  plugin/
    lang/                — per-language declarations (populates registry)
    blink.lua            — reads registry → sets up completion (UIEnter)
    conform.lua          — reads registry → sets up formatting (VimEnter)
    dap.lua              — reads registry → sets up debugging (deferred to first use)
    lint.lua             — reads registry → sets up linting (VimEnter)
    lsp.lua              — reads registry → enables LSP servers (UIEnter)
    lualine.lua          — reads registry → sets up statusline (VimEnter)
    mason.lua            — reads registry → installs tools (VimEnter)
    neotest.lua          — reads registry → sets up testing (deferred to first use)
    <name>.lua           — other feature plugins (snacks, treesitter, oil, etc.)
  after/
    lsp/                 — overrides for LSP configs from packages
    queries/<lang>/      — treesitter query extensions (injections.scm, etc.)
    syntax/<ft>.vim       — legacy syntax overrides/extensions
  ftplugin/              — per-filetype editor settings (vim.opt_local only)
```

**`init.lua`** — Minimal entrypoint: leader keys, `require("options")`,
diagnostics config. Docs: `:h initialization`

**`lua/`** — Lua modules loaded via `require()`. Never auto-sourced.
Includes `registry.lua` (central typed registry), `merge.lua` (deep merge
with list append+dedup), `defer.lua` (VimEnter/UIEnter setup queues),
`options.lua` (editor options), and shared utilities (fold, toggle, pickers).

**`lua/registry.lua`** — Typed central registry module. Lang files call
`require("registry").add({...})` with a `RegistrySpec` table. Internally
uses `merge()` to aggregate contributions. Consumers read fields after
all plugin files have loaded.

**`lua/merge.lua`** — Reusable deep merge function. Appends and deduplicates
lists, recurses into dicts, overwrites scalars. Used by the registry and by
consumer plugins to merge base opts with registry contributions.

**`lua/defer.lua`** — Provides `on_vim_enter(fn)` and `on_ui_enter(fn)` for
queuing setup functions. VimEnter callbacks run after all plugin files have
loaded, ensuring the registry is fully populated. UIEnter callbacks run after
the first paint for heavier setup.

**`plugin/`** — Each file follows a consistent layout: `vim.pack.add()` →
`registry.add()` → `defer.on_vim_enter(fn)` → keymaps. Sourced alphabetically;
subdirectories included via the `**` glob. Docs: `:h initialization` (step 11)

**`plugin/lang/`** — One file per language. Declares requirements into
the registry via `require("registry").add({...})`. May also install
lang-specific plugins (`vim.pack.add()`) and register deferred autocmds.

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

Servers are enabled by the lsp.lua plugin, which reads `registry.lsp.servers`.
Lang files declare their servers via:

```lua
-- plugin/lang/go.lua
require("registry").add({ lsp = { servers = { "gopls" } } })
```

To disable a server: `vim.lsp.enable("gopls", false)`.

---

## Registry pattern

All `plugin/` files — both lang declarations and consumers — live in the same
directory. The timing guarantee comes from `defer.lua`, not from filesystem
ordering:

1. All `plugin/` files load (step 11): `vim.pack.add()` and `registry.add()`
   execute immediately
2. `VimEnter` fires (step 17): deferred setup functions run, reading from the
   fully-populated registry

This allows **any plugin to contribute data to any other plugin** via the
registry, regardless of filename ordering.

### RegistrySpec fields

Each plugin is namespaced under `registry.<name>`. Plugins with `setup(opts)`
store their opts under `.opts`:

| Field | Sub-fields | Description |
|---|---|---|
| `lsp` | `servers` | LSP server names for `vim.lsp.enable()` |
| `mason` | `opts`, `ensure_installed`, `pip_extra_packages` | Mason setup opts + tool lists |
| `conform` | `opts` | conform.setupOpts |
| `lint` | `linters_by_ft`, `linters` | No setup() — direct assignment |
| `blink` | `opts` | blink.cmp.Config |
| `code_runner` | `opts` | code_runner setup opts |
| `dap` | `adapters`, `configurations`, `setups` | No setup() — direct assignment |
| `neotest` | `opts` | neotest.Config |
| `lualine` | `opts`, `sections` | lualine setup opts (extensions via `opts`), named section components via `sections` (lualine decides placement) |

All merging is handled by `merge()` — a custom deep merge that **appends and
deduplicates lists** and **recurses into dicts**.

### Consumer pattern

Consumer plugins merge base opts with registry contributions:

```lua
-- plugin/mason.lua
require("defer").on_vim_enter(function()
  local merge = require("merge")
  local registry = require("registry")
  local opts = { PATH = "append" }
  require("mason").setup(merge(opts, registry.mason.opts or {}))
end)
```

Some registry fields live outside `.opts` to give the consumer full control over
placement. For example, lualine has a `.sections` field where contributors
register named components, and lualine.lua decides where to inject them:

```lua
-- plugin/dap.lua (contributor — declares what, not where)
require("registry").add({
  lualine = {
    sections = {
      dap = { function() return require("dap").status() end, cond = ..., icon = "" },
    },
  },
})

-- plugin/lualine.lua (consumer — decides placement)
local sections = registry.lualine.sections or {}
if sections.dap then
  table.insert(opts.sections.lualine_x, 1, sections.dap)
end
```

### Plugin file layout

Every plugin file follows a consistent structure:

```lua
-- 1. Load packages (immediate)
vim.pack.add(...)

-- 2. Build hooks (immediate, runs on install/update)
vim.api.nvim_create_autocmd("PackChanged", { ... })

-- 3. Registry contributions (immediate)
require("registry").add({ ... })

-- 4. Deferred setup (VimEnter/UIEnter)
require("defer").on_vim_enter(function()
  local merge = require("merge")
  local registry = require("registry")
  local opts = { ... }
  require("plugin").setup(merge(opts, registry.<name>.opts or {}))
end)

-- 5. Keymaps
vim.keymap.set(...)
```

### Example lang file

```lua
-- plugin/lang/shell.lua
require("registry").add({
  lsp = { servers = { "bashls" } },
  mason = { ensure_installed = { "bash-language-server", "shfmt", "shellcheck" } },
  conform = {
    opts = { formatters_by_ft = { sh = { "shfmt" } } },
  },
  lint = {
    linters_by_ft = { sh = { "shellcheck" } },
  },
})
```

Lang files can also install plugins and register autocmds alongside declarations:

```lua
-- plugin/lang/python.lua
vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap-python", name = "nvim-dap-python" },
})

require("registry").add({
  lsp = { servers = { "basedpyright", "ruff" } },
  mason = { ensure_installed = { "basedpyright", "ruff", "mypy", "debugpy" } },
  lint = { linters_by_ft = { python = { "mypy" } } },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  once = true,
  callback = function()
    require("dap-python").setup("uv")
  end,
})
```

---

## Key idioms

**Self-contained plugin file** (the standard pattern):

```lua
-- plugin/oil.lua
vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
})

require("oil").setup({
  view_options = { show_hidden = true },
})

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Open file explorer" })
```

**Always** pass `{ clear = true }` to `nvim_create_augroup` — prevents
duplicate autocmds if the file is re-sourced.

**Deferred plugin file** (for plugins only used via keymaps — dap, neotest,
codediff, etc.). Keep `vim.pack.add()` at the top so the plugin is on the
packpath, but defer the expensive `require()` + `.setup()` to first use:

```lua
-- plugin/dap.lua
vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true
  require("dapui").setup()
  -- ... rest of setup
end

vim.keymap.set("n", "<leader>dc", function()
  init()
  require("dap").continue()
end, { desc = "Continue" })
```

**Deferred filetype-specific plugin** (csv, log, schemastore, etc.). Wrap
`require()` + `.setup()` in a `FileType` autocmd with `once = true`:

```lua
-- plugin/lang/csv.lua
vim.pack.add({
  { src = "https://github.com/hat0uma/csvview.nvim" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "csv",
  once = true,
  callback = function()
    require("csvview").setup()
  end,
})
```

**Build hooks** for plugins that need a build step after install or update.
Use the `PackChanged` autocmd:

```lua
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then
      vim.cmd("TSUpdate")
    end
  end,
})
```

Event data: `ev.data.kind` (`"install"`, `"update"`, `"delete"`),
`ev.data.spec` (plugin spec), `ev.data.path` (full path to plugin directory).

**Do NOT defer** plugins needed from the first frame or first keystroke:
colorscheme, snacks (dashboard). Plugins like blink, lualine, LSP, mason
use `defer.on_vim_enter()` or `defer.on_ui_enter()` for optimal timing.

**Profile startup with `--startuptime`:**

```sh
NVIM_APPNAME=nvim-native nvim --startuptime /tmp/startup.log --headless +q
```

The log columns are:

| Column | Meaning |
|--------|---------|
| **clock** | Wall clock time since process start (ms) |
| **self+sourced** | Total time for a file including everything it `require()`'d |
| **self** | Time spent in that file alone (excluding nested requires) |

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

1. `plugin/lang/<ft>.lua` — call `require("registry").add()` with `lsp`,
   `mason`, `conform`, `lint`:
   ```lua
   require("registry").add({
     lsp = { servers = { "pyright" } },
     mason = { ensure_installed = { "pyright", "ruff" } },
     conform = { opts = { formatters_by_ft = { python = { "ruff_format" } } } },
     lint = { linters_by_ft = { python = { "ruff" } } },
   })
   ```
2. `lsp/<server>.lua` — return the server config table (if custom config needed)
3. `ftplugin/<ft>.lua` — editor settings only (`vim.opt_local.*`)
4. *(optional)* `after/lsp/<server>.lua` — extend base LSP config

Do **not** add language-specific config to consumer plugin files — those
read from the registry only.

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
vim.keymap.set("n", "<leader>uf", require("toggle").auto_format, { desc = "Toggle auto-format" })
```
