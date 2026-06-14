# nvim-fredrik

![screenshot](https://github.com/user-attachments/assets/147570ce-09f5-44cb-b30c-dc172b59fdb3)

## Usage

```sh
NVIM_APPNAME=nvim-fredrik nvim
```

Symlinked via GNU Stow. Run `./rebuild.sh --stow` from `~/.dotfiles/` to apply.

## Structure

```
nvim-fredrik/
  init.lua                    requires core modules
  lua/                        libraries called by init.lua and plugins
  plugin/                     plugins, often deferred to load on VimEnter
    lang/                     per-language plugins, filetypes, editor settings, autocmds
  ftplugin/                   (unused; use plugin/lang instead)
  lsp/                        (unused; nvim-lspconfig provides base configs)
  after/
    lsp/                      overrides for nvim-lspconfig base configs
```

## Architecture

The `init.lua` defines `_G.Config` (for global states), `vim.opt` options, some
keymaps and custom behaviors.

Core plugin files (`plugin/*.lua`) own each plugin's host setup and any config
shared across languages (e.g. completion sources). Anything language-specific is
contributed by the language files.

Language files (`plugin/lang/*.lua`) handle language-specific concerns: which
LSP servers, Mason tools, formatters, linters and test adapters a language uses
(declared via `require("lang").register()`, see
[Adding new language support](#adding-new-language-support)), plus per-filetype
editor settings (`vim.opt_local` via `FileType` autocmds), extra
`vim.pack.add()` calls, custom filetypes, SchemaStore loading, build hooks, and
autocmds.

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
require("lang").register("work", {
    mason = { "mdformat" },
    mason_pip = {
        mdformat = {
            "mdformat-gfm==1.0.0",
            "mdformat-admon==2.1.1",
            "mdformat-front-matters==2.0.0",
        },
    },
})

require("lazyload").on_override(function()
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

A language describes its own tooling in `plugin/lang/<ft>.lua` via
`require("lang").register()` at the **top level** of the file. The core plugins
(`lsp.lua`, `mason.lua`, `conform.lua`, `lint.lua`, `code_runner.lua`,
`nvim_coverage.lua`, `neotest.lua`, `dap.lua`) read the merged spec via
`require("lang").spec()` at `VimEnter`, so registering is all that's needed to
wire up LSP, Mason, formatting, linting, file running, coverage, testing and
debugging.

The spec field names are the only vocabulary: they mirror the consumer's own
option names where one exists (conform's `formatters_by_ft`/`formatters`,
nvim-lint's `linters_by_ft`/`linters`), and `spec()` returns the merged result
under the same names.

```lua
-- plugin/lang/<ft>.lua
require("lang").register("<name>", {
  servers = { "<lspconfig_server>" },  -- e.g. "gopls"
  mason = { "<mason_package>" },         -- e.g. "gopls", "goimports"

  -- extra pip packages installed into a mason pypi package's venv
  -- (re-applied when mason installs/updates the package)
  mason_pip = { ["<mason_package>"] = { "<pip_package>==<version>" } },

  -- conform: which formatters run, and their config
  formatters_by_ft = { <ft> = { "<formatter>" } },
  formatters = { <formatter> = { prepend_args = { ... } } },

  -- nvim-lint: which linters run, and their config
  linters_by_ft = { <ft> = { "<linter>" } },
  linters = { <linter> = { args = { ... } } },

  -- imperative lint wiring that can't be a table (e.g. dynamic cwd); receives
  -- the nvim-lint module and runs inside lint.lua's VimEnter
  lint_setup = function(lint)
    -- custom autocmds, lint.try_lint(...) with computed cwd, etc.
  end,

  -- code_runner.nvim filetype command(s)
  code_runner = { <ft> = { "<command>" } },

  -- nvim-coverage per-language config
  coverage = {
    <ft> = { coverage_file = function() return "coverage.out" end },
  },

  -- neotest: the per-language adapter plugin(s) and a builder returning the
  -- adapter. packs are batch-added by neotest.lua before any builder runs, then
  -- every adapter is collected into neotest's single setup({ adapters = ... }).
  neotest = {
    packs = { { src = "https://github.com/<adapter-plugin>" } },
    adapter = function()
      return require("<adapter>")({ --[[ adapter opts ]] })
    end,
  },

  -- dap: the per-language adapter plugin(s) and an imperative setup hook. packs
  -- are batch-added by dap.lua before any hook runs; each hook receives the dap
  -- module and wires up dap.adapters/dap.configurations (or calls the adapter's
  -- own setup).
  dap = {
    packs = { { src = "https://github.com/<adapter-plugin>" } },
    setup = function(dap)
      require("<adapter>").setup(--[[ adapter opts ]])
    end,
  },
})

require("lazyload").on_vim_enter(function()
  -- editor settings (vim.opt_local via FileType autocmd), plugins, filetypes,
  -- autocmds
end)
```

All fields are optional. `register()` **must** run at the top level (not inside
`on_vim_enter`) so it fires during plugin sourcing, before any consumer reads
the registry.

The `neotest`/`dap` `packs` are ordinary `vim.pack` specs (so they take
`version`, etc.); the consumer batch-adds them in one call before running any
builder/hook, so adapters never each install separately or race on load order.

The only tool config that stays in a core plugin is config shared across
languages — currently just `prettier` (used by markdown and js/ts) in
`conform.lua`. Everything language-specific lives in its `plugin/lang/<ft>.lua`.

_(optional)_ `after/lsp/<server>.lua` — override the base config from
nvim-lspconfig.
