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
    registry.lua              central registry — lang files declare, aggregators read
    options.lua               all vim.opt settings
    diagnostics.lua           diagnostic display config
    fold.lua                  fold helpers (treesitter default + LSP override)
    toggle.lua                toggle functions (auto-format, inlay hints)
    colors.lua                color utility (blend)
  lsp/                        one file per LSP server (auto-discovered)
  plugin/
    lang/                     per-language declarations (populates registry)
    colorscheme.lua           zenbones + OSC11 dark/light detection
    oil.lua                   file explorer
    snacks.lua                QoL (picker, dashboard, lazygit, terminal)
    treesitter.lua            syntax highlighting + context
    ...                       other feature plugins
  after/
    plugin/
      blink.lua               reads registry → sets up completion
      conform.lua             reads registry → sets up formatting
      dap.lua                 reads registry → sets up debugging (deferred to first use)
      lint.lua                reads registry → sets up linting
      lsp.lua                 reads registry → enables LSP servers
      lualine.lua             reads registry → sets up statusline (VimEnter re-setup)
      mason.lua               reads registry → installs tools
      neotest.lua             reads registry → sets up testing (deferred to first use)
    lsp/
      gopls.lua               extends gopls for templ/gotmpl
  ftplugin/                   per-filetype editor settings (vim.opt_local)
```

## Registry pattern

The config uses a **declare → collect → setup** flow:

1. `plugin/lang/*.lua` files call `require("registry").add({...})` with typed
   specs (LSP servers, mason tools, conform formatters, lint linters)
2. `after/plugin/*.lua` aggregators read from the registry and call setup()

This inverts the old pattern where aggregators loaded first and lang files had
to mutate their internal state after the fact.

```lua
-- plugin/lang/go.lua
require("registry").add({
  lsp_servers = { "gopls" },
  mason_tools = { "gopls", "goimports", "gci", "gofumpt", "golines", "golangci-lint" },
  conform = {
    formatters_by_ft = { go = { "goimports", "gci", "gofumpt", "golines" } },
    formatters = { goimports = { args = { "-srcdir", "$FILENAME" } } },
  },
  lint = {
    linters_by_ft = { go = { "golangcilint" } },
  },
})
```

**Load order guarantees:**
1. `plugin/lang/*.lua` runs during `plugin/` phase → populates registry
2. `after/plugin/*.lua` runs after all `plugin/` files → reads registry, calls setup()
3. FileType/BufEnter events fire when buffers open → after everything is loaded

## Per-project overrides

Place a `.nvim.lua` in any project directory. It runs at step 7c of
initialization — **before** `plugin/` and `after/plugin/` files (`:h exrc`).
Wrap plugin overrides in a `VimEnter` autocmd so they apply after all plugins
are loaded.

## Plugin management

- **Install**: `vim.pack.add()` in each file. New plugins install on first launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding a new language

1. `plugin/lang/<ft>.lua` — call `require("registry").add()` with lsp_servers,
   mason_tools, conform, lint
2. `lsp/<server>.lua` — return the server config table (if custom config needed)
3. `ftplugin/<ft>.lua` — editor settings only (`vim.opt_local.*`)
4. *(optional)* `after/lsp/<server>.lua` — extend base LSP config

## Todo

Registry-driven aggregators:

- [x] mason.lua
- [x] lsp.lua
- [x] conform.lua
- [x] lint.lua
- [x] blink.lua
- [x] neotest.lua

## Startup performance

Keymap-only and filetype-specific plugins defer `require()` + `.setup()` to
first use (see pattern in neotest.lua, dap.lua, codediff.lua, etc). The
`vim.pack.add()` calls stay at the top level so plugins are always on the
packpath.

| Phase | What runs |
|-------|-----------|
| `plugin/` | lualine, snacks, treesitter, and other feature plugins |
| `plugin/lang/` | 23 files calling `require("registry").add({...})` — pure table ops, <0.1ms each |
| `after/plugin/` | blink, conform, dap, lint, lsp, lualine, mason, neotest — read registry, call setup() |

Potential further wins:

- [ ] render_markdown.lua — defer to `FileType markdown` (~10ms)
- [ ] oil.lua — defer if directory-open at startup can be handled
