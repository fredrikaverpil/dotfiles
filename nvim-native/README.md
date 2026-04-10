# nvim-native

A Neovim config using only native conventions and `vim.pack` (v0.12.0+) for
package management. No plugin manager framework — just Neovim's built-in
directory structure doing what it was designed to do.

## Usage

```sh
NVIM_APPNAME=nvim-native nvim
```

Symlinked via GNU Stow. Run `./rebuild.sh --stow` from `~/.dotfiles/` to apply.

## Structure

```
nvim-native/
  init.lua                    leader keys, require("options"), diagnostics, debug/profile
  lua/
    registry.lua              central registry — lang files declare, consumers read
    merge.lua                 deep merge helper (appends lists, recurses dicts)
    defer.lua                 VimEnter/UIEnter deferred setup queues
    options.lua               all vim.opt settings
    diagnostics.lua           diagnostic display config
    fold.lua                  fold helpers (treesitter default + LSP override)
    toggle.lua                toggle functions (auto-format, inlay hints)
    colors.lua                color utility (blend)
  lsp/                        one file per LSP server (auto-discovered)
  plugin/
    lang/                     per-language declarations (populates registry)
    blink.lua                 reads registry → sets up completion (UIEnter)
    conform.lua               reads registry → sets up formatting (VimEnter)
    dap.lua                   reads registry → sets up debugging (deferred to first use)
    lint.lua                  reads registry → sets up linting (VimEnter)
    lsp.lua                   reads registry → enables LSP servers (UIEnter)
    lualine.lua               reads registry → sets up statusline (VimEnter)
    mason.lua                 reads registry → installs tools (VimEnter)
    neotest.lua               reads registry → sets up testing (deferred to first use)
    colorscheme.lua           zenbones + OSC11 dark/light detection
    oil.lua                   file explorer
    snacks.lua                QoL (picker, dashboard, lazygit, terminal)
    treesitter.lua            syntax highlighting + context
    ...                       other feature plugins
  after/
    lsp/
      gopls.lua               extends gopls for templ/gotmpl
  ftplugin/                   per-filetype editor settings (vim.opt_local)
```

## Registry pattern

The config uses a **register immediately, consume deferred** flow:

1. All `plugin/` files load (alphabetically): `vim.pack.add()` and
   `registry.add()` execute immediately
2. `VimEnter` fires: deferred setup functions run, reading from the
   fully-populated registry via `defer.on_vim_enter()` or `defer.on_ui_enter()`

No `after/plugin/` needed — the `defer.lua` module provides the timing
guarantee that all data is registered before any consumer reads it.

Each plugin is namespaced under `registry.<name>`. Plugins with a `setup(opts)`
store their opts under `.opts`:

```lua
-- plugin/lang/go.lua
require("registry").add({
  lsp = { servers = { "gopls" } },
  mason = { ensure_installed = { "gopls", "goimports", "gci", "gofumpt", "golines", "golangci-lint" } },
  conform = {
    opts = {
      formatters_by_ft = { go = { "goimports", "gci", "gofumpt", "golines" } },
      formatters = { goimports = { args = { "-srcdir", "$FILENAME" } } },
    },
  },
  lint = {
    linters_by_ft = { go = { "golangcilint" } },
  },
})
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

### Consumer pattern

Consumers merge base opts with registry contributions using `merge()`:

```lua
-- merge() deep-merges tables, appending+deduplicating lists
local opts = { PATH = "append" }
require("mason").setup(merge(opts, registry.mason.opts or {}))
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

### Build hooks

Plugins that need a build step after install or update use the `PackChanged`
autocmd:

```lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then
      vim.cmd("TSUpdate")
    end
  end,
})
```

## Per-project overrides

Place a `.nvim.lua` in any project directory. It runs at step 7c of
initialization — **before** `plugin/` files (`:h exrc`).
Wrap plugin overrides in a `VimEnter` autocmd so they apply after all plugins
are loaded.

## Plugin management

- **Install**: `vim.pack.add()` in each file. New plugins install on first launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding a new language

1. `plugin/lang/<ft>.lua` — call `require("registry").add()` with `lsp`,
   `mason`, `conform`, `lint`
2. `lsp/<server>.lua` — return the server config table (if custom config needed)
3. `ftplugin/<ft>.lua` — editor settings only (`vim.opt_local.*`)
4. *(optional)* `after/lsp/<server>.lua` — extend base LSP config

## Startup performance

Keymap-only and filetype-specific plugins defer `require()` + `.setup()` to
first use (see pattern in neotest.lua, dap.lua, codediff.lua, etc). The
`vim.pack.add()` calls stay at the top level so plugins are always on the
packpath.

| Phase | What runs |
|-------|-----------|
| `plugin/` | All files: vim.pack.add + registry.add (immediate), setup queued via defer |
| `plugin/lang/` | 23 files calling `require("registry").add({...})` — pure table ops, <0.1ms each |
| `VimEnter` | Lualine (`{ sync = true }`), then everything else async (default) |
