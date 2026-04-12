# nvim-native

## Usage

```sh
NVIM_APPNAME=nvim-fredrik nvim
```

Symlinked via GNU Stow. Run `./rebuild.sh --stow` from `~/.dotfiles/` to apply.

## Structure

```
nvim-fredrik/
  init.lua                    requires core modules, debug_config, profile_config
  lua/
    debug_config.lua          OSV config (debug the config itself)
    profile_config.lua        profile.nvim config
    lazyload.lua                VimEnter/UIEnter deferred setup queues
    options.lua               all vim.opt settings
    fold.lua                  fold helpers (treesitter default + LSP override)
    toggle.lua                toggle functions (auto-format, inlay hints)
    colors.lua                color utility (blend)
    exrc.lua                  list project-local .nvim.lua files + trust status
  lsp/                        (unused; nvim-lspconfig provides base configs)
  plugin/
    lang/                     per-language plugins, filetypes, editor settings, autocmds
    diagnostics.lua           diagnostic display config
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
    treesitter.lua            syntax highlighting + context (VimEnter)
    ...                       other feature plugins
  after/
    lsp/                      overrides for nvim-lspconfig base configs
```

## Architecture

The `init.lua` defines `_G.Config` (for global states), `vim.opt` options, some
keymaps and custom behaviors.

Core plugin files (`plugin/*.lua`) own all tool configuration inline — LSP
servers, formatters, linters, completion sources, DAP adapters, neotest
adapters, etc.

Language files (`plugin/lang/*.lua`) handle language-specific concerns that
don't fit in the core plugins: per-filetype editor settings (`vim.opt_local` via
`FileType` autocmds), extra `vim.pack.add()` calls, custom filetypes,
SchemaStore loading, build hooks, and autocmds.

### Plugin file layout

Every plugin strives to lazy-load (except when they cannot). Helper functions
are available in the `lazyload` module.

```lua
-- Deferred setup (VimEnter/UIEnter)
require("lazyload").on_vim_enter(function()
  -- Build hooks (must be registered BEFORE vim.pack.add)
  vim.api.nvim_create_autocmd("PackChanged", { ... })

  -- Load packages (immediate)
  vim.pack.add(...)

  -- Configure plugin
  require("plugin").setup({ ... })

  -- Set keymap(s)
  vim.keymap.set( ... )
end)

-- 4. Keymaps
vim.keymap.set(...)
```

- `on_vim_enter(fn)`: defer to `VimEnter`, then run the function async
- `on_ui_enter(fn)`: defer to `UIEnter`, then run the function async
- `call_once(fn)`: call the function only once

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

Place a `.nvim.lua` in the the `$cwd` or above it. It runs at step 7c of
[initialization](https://neovim.io/doc/user/starting/#_initialization) —
**before** `plugin/` files (`:h exrc`).

In order to execute the `.nvim.lua` files _after_ `/plugin` files, a custom exrc
implementation was done in the `exrc` module.

Example:

```lua
-- ~/code/work/.nvim.lua
-- Override markdown formatter
require("conform").formatters_by_ft.markdown = { "mdformat" }
require("conform").formatters.mdformat = {
    prepend_args = { "--number", "--wrap", "80" },
}

-- Override gopls settings
vim.lsp.config.gopls.settings = {
    gopls = {
        analyses = {
            ST1000 = false,
            ST1020 = false,
            ST1021 = false,
        },
    },
}
```

> [!ATTENTION]
>
> Overrides will load on `UIEnter`, but after any `on_ui_enter`-loaded plugin,
> and can therefore not override plugins loaded after that event.

## Plugin management

Use the `:Pack` TUI or the built-in commands:

- **Install**: `vim.pack.add()` in each file. New plugins install on first
  launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding a new language

1. Add the LSP server to `plugin/lsp.lua`
2. Add Mason tools to `plugin/mason.lua`
3. Add formatters to `plugin/conform.lua`
4. Add linters to `plugin/lint.lua`
5. `plugin/lang/<ft>.lua` — editor settings (`vim.opt_local` via `FileType`
   autocmd), plugins, filetypes, autocmds
6. _(optional)_ `after/lsp/<server>.lua` — override base config from
   nvim-lspconfig
