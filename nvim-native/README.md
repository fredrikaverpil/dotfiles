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
    lazyload.lua                VimEnter/UIEnter deferred setup queues
    options.lua               all vim.opt settings
    diagnostics.lua           diagnostic display config
    fold.lua                  fold helpers (treesitter default + LSP override)
    toggle.lua                toggle functions (auto-format, inlay hints)
    colors.lua                color utility (blend)
    exrc.lua                  list project-local .nvim.lua files + trust status
  lsp/                        (unused; nvim-lspconfig provides base configs)
  plugin/
    lang/                     per-language plugins, filetypes, editor settings, autocmds
    blink.lua                 completion (VimEnter)
    conform.lua               formatting (VimEnter)
    dap.lua                   debugging (deferred to first use)
    lint.lua                  linting (VimEnter)
    lsp.lua                   LSP servers (VimEnter)
    lualine.lua               statusline (VimEnter)
    mason.lua                 tool installation (VimEnter)
    neotest.lua               testing (deferred to first use)
    colorscheme.lua           zenbones + OSC11 dark/light detection
    oil.lua                   file explorer
    snacks.lua                QoL (picker, dashboard, lazygit, terminal)
    treesitter.lua            syntax highlighting + context
    ...                       other feature plugins
  after/
    lsp/                      overrides for nvim-lspconfig base configs
      gopls.lua               extends gopls for templ/gotmpl
```

## Architecture

Core plugin files (`plugin/*.lua`) own all tool configuration inline — LSP
servers, formatters, linters, completion sources, DAP adapters, neotest
adapters, etc. Language files (`plugin/lang/*.lua`) handle language-specific
concerns that don't fit in the core plugins: per-filetype editor settings
(`vim.opt_local` via `FileType` autocmds), extra `vim.pack.add()` calls,
custom filetypes, SchemaStore loading, build hooks, and autocmds.

### Plugin file layout

Every plugin file follows a consistent structure:

```lua
-- 1. Build hooks (must be registered BEFORE vim.pack.add)
vim.api.nvim_create_autocmd("PackChanged", { ... })

-- 2. Load packages (immediate)
vim.pack.add(...)

-- 3. Deferred setup (VimEnter/UIEnter)
require("lazyload").on_vim_enter(function()
  require("plugin").setup({ ... })
end)

-- 4. Keymaps
vim.keymap.set(...)
```

### Build hooks

Plugins that need a build step after install or update use the `PackChanged`
autocmd. Hooks must be registered **before** the `vim.pack.add()` call so they
fire on first bootstrap:

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
Wrap plugin overrides in `require("lazyload").on_override(...)` so they apply
after all deferred plugin setup has completed.

## Plugin management

- **Install**: `vim.pack.add()` in each file. New plugins install on first launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding a new language

1. Add the LSP server to `plugin/lsp.lua`
2. Add Mason tools to `plugin/mason.lua`
3. Add formatters to `plugin/conform.lua`
4. Add linters to `plugin/lint.lua`
5. `plugin/lang/<ft>.lua` — editor settings (`vim.opt_local` via `FileType` autocmd), plugins, filetypes, autocmds
6. *(optional)* `after/lsp/<server>.lua` — override base config from nvim-lspconfig

## Startup performance

Keymap-only and filetype-specific plugins defer `require()` + `.setup()` to
first use (see pattern in neotest.lua, dap.lua, codediff.lua, etc). The
`vim.pack.add()` calls stay at the top level so plugins are always on the
packpath.

| Phase | What runs |
|-------|-----------|
| `plugin/` | All files: vim.pack.add (immediate), setup queued via lazyload |
| `VimEnter` | Lualine (`{ sync = true }`), then everything else async (default) |
