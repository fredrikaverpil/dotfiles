# Startup sequence and runtime directories

## Startup sequence (`:h initialization`)

| Step   | What happens                                                              |
| ------ | ------------------------------------------------------------------------- |
| 1      | Set `'shell'` from `$SHELL`                                               |
| 2      | Process arguments, execute `--cmd` args, create buffers (not loaded yet)  |
| 3      | Start server, set `v:servername`                                          |
| 4      | Wait for UI to connect (if `--embed`)                                     |
| 5      | Setup default mappings and autocmds                                       |
| 6      | Enable filetype and indent plugins (`:runtime! ftplugin.vim indent.vim`)  |
| **7a** | System vimrc (`sysinit.vim`)                                              |
| **7b** | **User config (`init.lua`)** -- leader keys, `require("options")`, etc.   |
| **7c** | **`.nvim.lua` (exrc)** -- project-local config, if `'exrc'` is on         |
| 8      | Enable filetype detection (`:runtime! filetype.lua`)                      |
| 9      | Enable syntax highlighting                                                |
| 10     | Set `v:vim_did_init = 1`                                                  |
| **11** | **Load plugins**: `plugin/**/*.lua`, then packages, then `after/` plugins |
| 12     | Set `'shellpipe'` and `'shellredir'`                                      |
| 13     | Set `'updatecount'` to zero if `-n` was given                             |
| 14     | Set binary options if `-b` was given                                      |
| 15     | Read ShaDa file                                                           |
| 16     | Read quickfix file if `-q` was given                                      |
| 17     | Open windows, load buffers -> triggers **`VimEnter`**, then **`UIEnter`** |

All `plugin/` files run at step 11. `VimEnter` (step 17) fires **after**
everything. `lazyload.lua` queues setup callbacks to run at VimEnter/UIEnter --
async by default (via `vim.schedule()`), or synchronous with `{ sync = true }`.
Only lualine uses `{ sync = true }`; everything else runs async.

## Runtime directories

Neovim searches these in every runtimepath entry (`:h 'runtimepath'`):

| Directory                 | When                    | Purpose                                                                       |
| ------------------------- | ----------------------- | ----------------------------------------------------------------------------- |
| `init.lua`                | Step 7b, once           | Leader keys, `require("options")`, diagnostics                                |
| `lua/`                    | On `require()`          | Lua modules (never auto-sourced)                                              |
| `plugin/**/*.lua`         | Step 11, once           | Plugin install + setup (alphabetical, subdirs included)                       |
| `ftplugin/<ft>.lua`       | Per-buffer, on FileType | Buffer-local settings (`vim.opt_local`)                                       |
| `indent/<ft>.lua`         | Per-buffer, on FileType | Indent expressions                                                            |
| `syntax/<ft>.vim`         | Per-buffer, on FileType | Legacy syntax highlighting (treesitter overrides)                             |
| `lsp/<server>.lua`        | Startup (discovery)     | LSP config tables, auto-discovered by `vim.lsp.config` (see after/lsp/ below) |
| `parser/<lang>.so`        | On demand               | Treesitter parsers                                                            |
| `queries/<lang>/*.scm`    | On demand               | Treesitter queries (highlights, injections, folds, indents)                   |
| `colors/<name>.{vim,lua}` | On demand               | Colorschemes, loaded by `:colorscheme`                                        |
| `autoload/`               | On first call           | Auto-loaded Vimscript/Lua functions                                           |
| `compiler/`               | On `:compiler`          | Compiler settings                                                             |
| `spell/`                  | On demand               | Spell checking files                                                          |

### after/

The `after/` tree loads _after_ all non-after paths. This config uses
nvim-lspconfig for base LSP server configs and puts **overrides** in
`after/lsp/` (not `lsp/`). Because nvim-lspconfig ships its own `lsp/` defaults,
placing overrides in `after/lsp/` ensures they take precedence. `:h
after-directory`

### Per-project overrides (exrc)

With `vim.opt.exrc = true` (set in `lua/options.lua`), Neovim sources
`.nvim.lua` from the current working directory at **step 7c** -- **before**
`plugin/` files (step 11), and before filetype detection (step 8). This is the
native equivalent of lazy.nvim's `.lazy.lua`. `:h exrc`, `:h initialization`

Because `.nvim.lua` runs before plugins, direct `require("conform").setup()`
calls will be overwritten by plugin setup at VimEnter. Use
`lazyload.on_override` to patch plugin config per-project -- it runs after all
VimEnter callbacks:

```lua
-- .nvim.lua (project root)
require("lazyload").on_override(function()
  require("conform").setup({
    formatters_by_ft = { markdown = { "mdformat" } },
  })
end)
```

### Note

The `LspAttach` autocmd (in the lsp.lua plugin file) bridges startup and
per-buffer: keymaps are registered per-buffer when the LSP server attaches, even
though the autocmd itself is registered once at startup.

## Documentation

Docs ship with Neovim at `$VIMRUNTIME/doc/`. With Bob-managed nightly the path
is `~/.local/share/bob/nightly/share/nvim/runtime/doc/`. Read with `:h <tag>`
inside Neovim or directly with your editor/pager. Online mirror:
https://neovim.io/doc/user/

| Topic                     | Help tag              | File           |
| ------------------------- | --------------------- | -------------- |
| Startup & init order      | `:h initialization`   | `starting.txt` |
| Native package manager    | `:h vim.pack`         | `pack.txt`     |
| packages / packpath       | `:h packages`         | `pack.txt`     |
| LSP config auto-discovery | `:h lsp-config`       | `lsp.txt`      |
| Enable/disable servers    | `:h vim.lsp.enable()` | `lsp.txt`      |
| ftplugin directory        | `:h ftplugin`         | `usr_41.txt`   |
| after/ directory          | `:h after-directory`  | `options.txt`  |
| runtimepath               | `:h runtimepath`      | `options.txt`  |
| autoload/                 | `:h autoload`         | `userfunc.txt` |
| colors/                   | `:h colorscheme`      | `syntax.txt`   |

## Standard paths

| Purpose        | Lua                                         | Typical path             |
| -------------- | ------------------------------------------- | ------------------------ |
| Config dir     | `vim.fn.stdpath("config")`                  | `~/.config/nvim`         |
| Data dir       | `vim.fn.stdpath("data")`                    | `~/.local/share/nvim`    |
| Plugin install | `stdpath("data") .. "/site/pack/core/opt/"` | --                       |
| State dir      | `vim.fn.stdpath("state")`                   | `~/.local/state/nvim`    |
| Runtime        | `vim.fn.expand("$VIMRUNTIME")`              | `.../share/nvim/runtime` |
| Cache          | `vim.fn.stdpath("cache")`                   | `~/.cache/nvim`          |

With `NVIM_APPNAME=nvim-fredrik`, paths use `nvim-fredrik` instead of `nvim`.
