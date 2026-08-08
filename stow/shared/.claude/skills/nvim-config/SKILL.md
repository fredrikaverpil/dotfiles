---
name: nvim-config
description: >
  Native Neovim config idioms and conventions — use whenever writing, reviewing,
  or modifying any Neovim configuration that uses Neovim's built-in conventions
  WITHOUT a plugin manager framework (no lazy.nvim, packer, etc.). Covers
  directory structure, vim.pack plugin management, lsp/ auto-discovery, plugin/
  loading order, keymaps, and standard paths. Trigger on any task involving
  init.lua, plugin/*.lua, lsp/*.lua, vim.pack.add(), vim.lsp.enable(), or
  "native neovim config" — even if the user just says "add a plugin" or
  "configure LSP" in a native-style config.
---

# Native Neovim config

Conventions for Neovim configs built on `vim.pack`, `lsp/` and `plugin/` with no
plugin manager framework. Requires Neovim >= v0.12.0.

References — read the one the task needs:

| File                             | Covers                                                                                         |
| -------------------------------- | ---------------------------------------------------------------------------------------------- |
| `references/loading-patterns.md` | `vim.pack.add`'s `load` option, the three loading patterns, build hooks, profiling             |
| `references/plugin-files.md`     | File skeleton per pattern, `_G.Config` sharing, `do/end` blocks, ftplugin, option interfaces   |
| `references/startup.md`          | `:h initialization` step table, runtime directories, `after/`, exrc, help tags, standard paths |

## This config's location

The native config lives at **`~/.dotfiles/nvim-fredrik/`** inside the dotfiles
repo. It is symlinked into place via GNU Stow:

```
~/.dotfiles/nvim-fredrik/          <- actual files (edit here)
~/.dotfiles/stow/shared/.config/nvim-fredrik -> ../../../nvim-fredrik  (stow entry)
~/.config/nvim-fredrik -> ~/.dotfiles/stow/shared/.config/nvim-fredrik  (stow result)
```

Launch it with `NVIM_APPNAME=nvim-fredrik nvim`. Apply stow symlinks after
changes with `cd ~/.dotfiles/stow && stow --target="$HOME" --restow
--no-folding --adopt shared "$(uname -s)"`. Neovim itself is managed by
[Bob](https://github.com/MordechaiHadad/bob), not nixpkgs -- binary at
`~/.local/share/bob/nvim-bin/nvim`.

## Architecture

No framework -- each directory has a single responsibility:

| Layer               | Directory         | Role                                                                                     |
| ------------------- | ----------------- | ---------------------------------------------------------------------------------------- |
| **options**         | `lua/options.lua` | All `vim.opt` settings, required from `init.lua`                                         |
| **utility**         | `lua/`            | Shared Lua modules: `lazyload.lua`, `merge.lua`, `fold.lua`, `toggle.lua`, pickers, etc. |
| **plugins**         | `plugin/`         | Self-contained plugin files: install + setup + keymaps                                   |
| **lang plugins**    | `plugin/lang/`    | Per-language plugin installs, custom filetypes, autocmds, and setup                      |
| **editor settings** | `ftplugin/`       | Per-filetype `vim.opt_local` (indent, wrap, conceal)                                     |
| **server config**   | `after/lsp/`      | All LSP server config tables (in after/ to override package defaults)                    |

```
~/.config/nvim-fredrik/
  init.lua               -- leader keys, require("options"), diagnostics, keymaps
  lua/
    lazyload.lua         -- VimEnter/UIEnter deferred setup queues
    merge.lua            -- deep merge helper (appends+deduplicates lists, recurses dicts)
    options.lua          -- all vim.opt settings
    dev.lua              -- local dev plugin loader
    ...                  -- other utility modules (fold, toggle, pickers, icons, etc.)
  lsp/                   -- (unused; nvim-lspconfig provides base configs)
  parser/                -- treesitter parser .so files (managed by nvim-treesitter)
  colors/                -- custom colorschemes (loaded by :colorscheme)
  snippets/              -- custom snippet files (loaded by blink.cmp)
  ftplugin/              -- per-filetype editor settings (vim.opt_local)
  plugin/
    lang/                -- per-language plugins, custom filetypes, autocmds
    blink.lua            -- completion (VimEnter)
    conform.lua          -- formatting (VimEnter)
    dap.lua              -- debugging (deferred to first use)
    lint.lua             -- linting (VimEnter)
    lsp.lua              -- LSP enable + LspAttach keymaps (VimEnter)
    lualine.lua          -- statusline (VimEnter, sync)
    mason.lua            -- tool installation (VimEnter)
    neotest.lua          -- testing (deferred to first use)
    <name>.lua           -- other feature plugins (snacks, treesitter, oil, etc.)
  after/
    lsp/                 -- all LSP server configs (overrides package defaults)
    queries/<lang>/      -- treesitter query extensions (injections.scm, etc.)
    syntax/<ft>.vim      -- legacy syntax overrides/extensions
```

Notes on the layers:

- **`lua/lazyload.lua`** provides `on_vim_enter(fn, opts?)` and `on_ui_enter(fn,
  opts?)` for queuing setup functions. Default is async (via `vim.schedule()`);
  `{ sync = true }` runs synchronously. Also provides `on_override(fn)` for
  project-local overrides (runs after all VimEnter callbacks). Only lualine uses
  `{ sync = true }`.
- **`lua/merge.lua`** deep-merges: appends and deduplicates lists, recurses into
  dicts, overwrites scalars. `vim.NIL` as a value removes a key.
- **`lua/dev.lua`** loads a plugin from a local clone if it exists, otherwise
  falls back to `vim.pack.add()`.
- **`plugin/`** files are self-contained: `vim.pack.add()` -> setup -> keymaps.
  Sourced alphabetically at step 11; subdirectories included via the `**` glob.
- **`plugin/lang/`** is one file per language, only for languages needing
  genuinely language-specific wiring: plugins, custom filetypes
  (`vim.filetype.add`), build hooks, autocmds. Tool config (servers, formatters,
  linters) lives inline in the core plugin files; per-filetype editor settings
  live in `ftplugin/`.

## vim.pack

```lua
vim.pack.add({
  "https://github.com/user/repo",                                    -- string form
  { src = "https://github.com/user/repo" },                          -- table form
  { src = "https://github.com/user/repo", name = "repo" },           -- custom name
  { src = "https://github.com/user/repo", version = "main" },                   -- branch/tag/commit
  { src = "https://github.com/user/repo", version = vim.version.range("1.*") }, -- semver range
})

vim.pack.update()                             -- interactive update with confirmation buffer
vim.pack.update({"name"}, { force = true })   -- update specific plugin, skip confirm
vim.pack.del({"name"})                        -- remove from disk
vim.pack.get()                                -- list all managed plugins
```

Install location is `stdpath("data") .. "/site/pack/core/opt/<name>"`; the
lockfile is `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`, committed to VCS.

**No URL shorthand helpers** in this config. The upstream docs suggest a `local
gh = function(x) ... end`, but since `vim.pack.add()` is scattered across many
`plugin/` files (one per plugin), a central helper adds no value. Use full URLs.

The `load` option decides which of the three loading patterns a file uses — see
`references/loading-patterns.md`.

## after/lsp/ config files

Each file returns a `vim.lsp.Config` table; the filename (without `.lua`)
becomes the server name. Placed in `after/lsp/` to override base configs shipped
by packages. No `setup()` call needed.

```lua
-- after/lsp/gopls.lua
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

Servers are enabled in `plugin/lsp.lua` via `vim.lsp.enable(servers)`. To
disable one: `vim.lsp.enable("gopls", false)`.

## Adding a new language

1. Add LSP server to the `servers` list in `plugin/lsp.lua`
2. Add mason tools to the `ensure_installed` list in `plugin/mason.lua`
3. Add formatters to `formatters_by_ft` in `plugin/conform.lua`
4. Add linters to `linters_by_ft` in `plugin/lint.lua`
5. Testing/debugging/coverage/running: `plugin/neotest.lua`, `plugin/dap.lua`,
   `plugin/nvim_coverage.lua`, `plugin/code_runner.lua`
6. _(if needed)_ `ftplugin/<ft>.lua` -- editor settings (`vim.opt_local`),
   unless Neovim's built-in ftplugin already covers them
7. _(if needed)_ `plugin/lang/<ft>.lua` -- language-specific plugins, custom
   filetypes, autocmds
8. _(optional)_ `after/lsp/<server>.lua` -- override nvim-lspconfig base config
