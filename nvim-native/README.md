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
    options.lua               all vim.opt settings
    diagnostics.lua           diagnostic display config
    fold.lua                  fold helpers (treesitter default + LSP override)
    toggle.lua                toggle functions (auto-format, inlay hints)
    colors.lua                color utility (blend)
  lsp/                        one file per LSP server (auto-discovered)
  plugin/
    core/                     foundation: blink, conform, lint, lsp, lualine, mason, snacks, lazydev, treesitter
    colorscheme.lua           zenbones + OSC11 dark/light detection
    code_runner.lua           code runner
    dap.lua                   debugging (nvim-dap + nvim-dap-ui)
    neotest.lua               testing (neotest + neotest-golang)
    oil.lua                   file explorer
    sidekick.lua              AI CLI integration
    tiny_inline_diagnostic.lua  inline diagnostics
    whichkey.lua              keymap popup
  after/
    plugin/lang/              per-language formatters/linters (extends core)
  ftplugin/                   per-filetype editor settings (vim.opt_local)
```

## Per-project overrides

Place a `.nvim.lua` in any project directory. It runs at step 7c of
initialization — **before** `plugin/` and `after/plugin/` files (`:h exrc`).
Wrap plugin overrides in a `VimEnter` autocmd so they apply after all plugins
are loaded.

## Plugin management

- **Install**: `vim.pack.add()` in each `plugin/*.lua` file. New plugins install
  on first launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding a new language

1. `lsp/<server>.lua` — return the server config table
2. `plugin/core/lsp.lua` — add to `vim.lsp.enable({})`
3. `plugin/core/mason.lua` — add tools to `ensure_installed`
4. `after/plugin/lang/<ft>.lua` — extend conform/lint for this filetype
5. `ftplugin/<ft>.lua` — editor settings only (`vim.opt_local.*`)

## Todo

Some aspects of the config centralizes concerns. Might be good to review and see
whether a central registry is a better approach:

- [ ] mason.lua
- [ ] blink.lua
- [ ] lsp.lua
- [ ] conform.lua
- [ ] lint.lua
- [ ] neotest.lua

## Startup performance

Keymap-only and filetype-specific plugins defer `require()` + `.setup()` to
first use (see pattern in neotest.lua, dap.lua, codediff.lua, etc). The
`vim.pack.add()` calls stay at the top level so plugins are always on the
packpath.

Remaining core plugins that load eagerly (hard to defer further):

| Plugin | ~ms | Why it must be eager |
|--------|-----|----------------------|
| mason | 33 | PATH setup needed before LSPs start |
| blink.cmp | 23 | Completion must be ready from first keystroke |
| lualine | 16 | Statusline visible from first frame |
| lsp | 16 | ~6ms is Neovim's own vim.lsp module; rest is vim.lsp.enable() |
| oil | 12 | Acts as netrw replacement; needed if `nvim .` |
| render_markdown | 10 | Could defer to FileType markdown |

Potential further wins:

- [ ] render_markdown.lua — defer to `FileType markdown` (~10ms)
- [ ] oil.lua — defer if directory-open at startup can be handled
