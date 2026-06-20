# nvim-fredrik

![screenshot](https://github.com/user-attachments/assets/147570ce-09f5-44cb-b30c-dc172b59fdb3)

## Usage

```sh
NVIM_APPNAME=nvim-fredrik nvim
```

Symlinked via GNU Stow. Run `./rebuild.sh --stow` from `~/.dotfiles/` to apply.

## Structure

```text
nvim-fredrik/
  init.lua                    requires core modules
  lua/                        libraries called by init.lua and plugins
  plugin/                     plugins, often deferred to load on VimEnter
    lang/                     per-language plugins, filetypes, autocmds
  ftplugin/                   per-filetype editor settings (indent, wrap, conceal)
  lsp/                        (unused; nvim-lspconfig provides base configs)
  after/
    lsp/                      overrides for nvim-lspconfig base configs
```

## Architecture

The `init.lua` defines `_G.Config` (for global states), `vim.opt` options, some
keymaps and custom behaviors.

Core plugin files (`plugin/*.lua`) each own **all** of their tool's
configuration inline: `conform.lua` lists every formatter, `lint.lua` every
linter, `lsp.lua` every server, `mason.lua` every tool, and so on. To see or
change a tool's setup you open that one file.

Language files (`plugin/lang/*.lua`) hold only what is genuinely
language-specific and cannot live in a shared plugin file: extra
`vim.pack.add()` calls for language-specific plugins, custom filetypes
(`vim.filetype.add`), SchemaStore loading, build hooks, and autocmds. Many
languages need none of this and so have no file at all.

Per-filetype editor settings (indent, wrap, conceal) live in `ftplugin/<ft>.lua`
— the native mechanism, sourced for every buffer of that filetype (including the
first one opened, which a `FileType` autocmd registered at `VimEnter` would
miss). Settings that Neovim's built-in ftplugins already provide (e.g. Go's
`noexpandtab`, Python's 4-space indent) are not duplicated.

I wrote
[a blog post](https://fredrikaverpil.github.io/blog/2026/04/15/from-lazy.nvim-to-vim.pack/)
on how I came to design it like this.

### Plugin file layout

Every plugin strives to lazy-load (except when they cannot). Helper functions
are available in the `lazyload` module.

```lua
-- Deferred setup (VimEnter)
require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("PackChanged", { ... })

  vim.pack.add(...)

  require("plugin").setup({ ... })

  vim.keymap.set( ... )
end)
```

- `on_vim_enter(fn)`: defer to `VimEnter`, then run the function async
- `on_override(fn)`: defer to after all `VimEnter` callbacks (for `.nvim.lua`
  overrides)

### Cross-plugin data sharing

Plugin files can pass data to each other through `_G.Config`, but it requires
them to be lazyloaded. Write to `_G.Config` at the **top level** of the file
(outside the `on_vim_enter` block), and read it inside the receiving plugin's
lazyload block:

```lua
-- plugin/producer.lua
Config.some_data = { "foo", "bar" }

require("lazyload").on_vim_enter(function()
  -- plugin logic
end)
```

```lua
-- plugin/consumer.lua
require("lazyload").on_vim_enter(function()
  local some_data = Config.some_data or {}
  -- plugin logic
end)
```

Top-level assignments execute when Neovim sources `plugin/` files (before any
`VimEnter` callback runs), so the data is always available by the time lazyload
blocks fire.

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

Example:

```lua
-- ~/code/work/.nvim.lua
--
-- install mdformat via mason, with the plugins pinned by einride/sage
-- (tools/sgmdformat/requirements.txt) in the mdformat venv
Config.mason_extra = {
    mason = { "mdformat" },
    mason_pip = {
        mdformat = {
            "mdformat-gfm==1.0.0",
            "mdformat-admon==2.1.1",
            "mdformat-front-matters==2.0.0",
        },
    },
}

require("lazyload").on_override(function()
    -- Override markdown formatter.
    -- Prefer the mason mdformat (it carries the pip extras pinned above);
    -- inside sage projects .sage/bin is ahead on $PATH and shadows it with a
    -- shim whose venv can break (e.g. Homebrew python upgrades), so resolve the
    -- mason binary explicitly. Fall back to $PATH mdformat when mason has none.
    require("conform").formatters_by_ft.markdown = { "mdformat" }
    require("conform").formatters.mdformat = {
        command = function()
            local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/mdformat"
            return vim.uv.fs_stat(mason_bin) and mason_bin or "mdformat"
        end,
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
end)
```

> [!NOTE]
>
> Overrides run after all `on_vim_enter` callbacks (including async ones), so
> they can patch any plugin state set up during `VimEnter`.

## Plugin management

Use the `:Pack` TUI or the built-in commands:

- **Install**: `vim.pack.add()` in each file. New plugins install on first
  launch.
- **Update**: `:lua vim.pack.update()` — review in confirmation buffer, `:w` to
  apply.
- **Lockfile**: `nvim-pack-lock.json` — commit to VCS for reproducible installs.

## Adding new language support

There is no registry — each tool is configured inline in its own core plugin
file. To add a language, edit the files for the tools it needs (all are plain
literal tables, so you see the whole picture for a tool in one place):

- **LSP**: add the server name to the `servers` list in `plugin/lsp.lua`.
- **Mason**: add the tool(s) to `ensure_installed` in `plugin/mason.lua`.
- **Formatting**: add `formatters_by_ft` (and any per-formatter config) in
  `plugin/conform.lua`.
- **Linting**: add `linters_by_ft` (and any per-linter config) in
  `plugin/lint.lua`. Imperative wiring (dynamic cwd, custom linters) goes in a
  `do`/`end` block in the same file.
- **Running files**: add a `filetype` command in `plugin/code_runner.lua`.
- **Coverage**: add a `lang` entry in `plugin/nvim_coverage.lua`.
- **Treesitter**: built-in parsers install on demand; custom parsers go in the
  `custom_parsers` table in both `plugin/nvim_treesitter.lua` and
  `plugin/arborist.lua`.
- **Completion**: add per-filetype providers in `plugin/blink.lua` (install the
  provider plugin itself from the language's `plugin/lang/<ft>.lua`).
- **Testing**: add the adapter pack and adapter in `plugin/neotest.lua`.
- **Debugging**: add the adapter pack and configuration in `plugin/dap.lua`.

For concerns that don't belong in a shared plugin file:

- **Editor settings** (indent, wrap, conceal): add `ftplugin/<ft>.lua` with
  `vim.opt_local` — but first check whether Neovim's built-in ftplugin already
  sets what you want (run `:e $VIMRUNTIME/ftplugin/<ft>.vim`); if so, don't
  duplicate it.
- **Language-specific plugins, custom filetypes, build hooks, autocmds**: add
  `plugin/lang/<ft>.lua` (see [Plugin file layout](#plugin-file-layout)).
  `vim.filetype.add` belongs at the top level of that file (so detection applies
  to the first buffer too), everything else inside `on_vim_enter`.
- **LSP server config**: add `after/lsp/<server>.lua` to override the
  nvim-lspconfig base config.

Project-local additions (a Mason tool / pip extras only needed in one repo) go
through `Config.mason_extra` in a `.nvim.lua` — see
[Per-project overrides](#per-project-overrides).
