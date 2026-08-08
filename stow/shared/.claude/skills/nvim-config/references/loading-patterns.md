# The three loading patterns

## The `load` option of `vim.pack.add`

- During `init.lua`/`plugin/` sourcing, defaults to `false` (`:packadd!` -- on
  runtimepath but the plugin's own `plugin/` files are deferred to Neovim's
  normal runtime loader pass instead of sourced inline).
- After startup, defaults to `true` (`:packadd` without bang -- the plugin's
  `plugin/` and `after/plugin/` files source immediately).
- Pass `load = true` explicitly when you need a plugin's `plugin/` files sourced
  right now (rare -- only matters if `vim.pack.add` runs during startup _and_
  something inspects the plugin's runtime state before step 11 finishes).
- Pass **`load = function() end`** (empty function) to register the plugin on
  disk without loading it at all. The plugin stays off the packpath entirely
  until you explicitly call `vim.cmd.packadd("<name>")`. This is the cornerstone
  of Pattern 3 below.

## Choosing a pattern

Three patterns cover every plugin in this config. Pick the one that matches
**when the plugin's code needs to run**, not how fancy you want the file to
look.

## Pattern 1: eager (setup at step 11)

Use when the plugin must take effect before the first paint, or when another
plugin's deferred setup callback or a pre-VimEnter autocmd `require()`s it.
Colorscheme, `snacks.nvim` (dashboard), `mini.icons`, `treesitter.lua`,
`blink.cmp` (dependency of `lsp.lua`'s callback).

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

## Pattern 2: deferred to VimEnter (pack.add inside the callback)

Use for plugins you want loaded every session but that don't need to be ready
before the first paint. This is the **default** pattern for deferred plugins in
this config. Fold `vim.pack.add` into the same `on_vim_enter` callback as
`setup()` so both the install/source cost and the setup cost land after startup
rather than at step 11:

```lua
-- plugin/conform.lua
vim.g.auto_format = true

require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/stevearc/conform.nvim" },
  })

  require("conform").setup({
    formatters_by_ft = {
      go = { "goimports", "gci", "gofumpt", "golines" },
      lua = { "stylua" },
    },
  })
end)

vim.keymap.set("n", "<leader>uf", require("toggle").auto_format, { desc = "Toggle auto-format" })
```

**Why not bare `vim.schedule()`?** `lazyload.on_vim_enter` gives you
sync-vs-async control, VimEnter/UIEnter split, and the `on_override` hook for
exrc overrides -- none of which bare `vim.schedule` provides.

**Build hooks (`PackChanged`) must stay eager** when the plugin uses this
pattern. Register the autocmd at file scope _before_ the `on_vim_enter` call --
autocmd registration is cheap and the hook needs to be live by the time the
deferred `vim.pack.add` triggers a first-bootstrap install.

## Pattern 3: truly lazy via `{ load = function() end }` (first use)

Use for plugins that may never run in a session: debuggers, test runners, diff
viewers, etc. The empty `load` callback registers the plugin on disk (so install
+ lockfile still work) but keeps it off the packpath entirely. The plugin is
fully invisible until the user triggers the first-use gate (typically a keymap,
command, or filetype autocmd), at which point `vim.cmd.packadd` brings it in:

```lua
-- plugin/dap.lua
local packages = {
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui", name = "nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio", name = "nvim-nio" },
}
vim.pack.add(packages, { load = function() end })

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  for _, p in ipairs(packages) do
    vim.cmd.packadd(p.name)
  end

  require("dapui").setup()
  -- ... rest of setup
end

vim.keymap.set("n", "<leader>dc", function()
  init()
  require("dap").continue()
end, { desc = "Continue" })
```

Notes:

- **Give every spec an explicit `name`**. The `init()` loop uses those names for
  `:packadd`, so leaving them implicit forces the file to re-derive the name
  from the URL.
- **`after/plugin/` files of the lazy-loaded plugin do not source**
  automatically via bare `:packadd`. `vim.pack`'s normal path sources them (see
  `pack.lua:801`) but the truly-lazy path bypasses that. If a plugin you
  lazy-load this way ships `after/plugin/*.lua` and you rely on them, source
  them manually in `init()`. (None of the config's current lazy plugins -- dap,
  neotest, codediff -- have `after/plugin/` files.)
- **Compare to Pattern 2**: Pattern 2 still loads the plugin every session, just
  not during startup. Pattern 3 doesn't load it at all if the user never
  triggers the gate. For DAP, you pay zero cost on sessions where you never
  debug.

## Deferred filetype-specific plugin

For csv, log, schemastore, etc. Wrap `require()` + `.setup()` in a `FileType`
autocmd with `once = true`:

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

## Local dev plugins

Via `lua/dev.lua` -- loads from a local clone if it exists, otherwise falls back
to `vim.pack.add()`:

```lua
-- plugin/lang/go.lua
require("dev").use({
  dev = "~/code/public/neotest-golang",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/neotest-golang" },
    })
  end,
})
```

## Build hooks (`PackChanged`)

Register the autocmd **before** the `vim.pack.add()` call that installs the
plugin, or the hook won't fire on first bootstrap.

```lua
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then
      vim.cmd("TSUpdate")
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})
```

Event data: `ev.data.kind` (`"install"`, `"update"`, `"delete"`), `ev.data.spec`
(plugin spec), `ev.data.path` (full path to plugin directory).

## What not to defer

Colorscheme and snacks (dashboard) are needed from the first frame or first
keystroke. Most plugins use `lazyload.on_vim_enter(fn)` (async). Only lualine
uses `lazyload.on_vim_enter(fn, { sync = true })` (synchronous, must be ready
before paint).

## Profiling startup

```sh
NVIM_APPNAME=nvim-fredrik nvim --startuptime /tmp/startup.log --headless +q
```

| Column           | Meaning                                                     |
| ---------------- | ----------------------------------------------------------- |
| **clock**        | Wall clock time since process start (ms)                    |
| **self+sourced** | Total time for a file including everything it `require()`'d |
| **self**         | Time spent in that file alone (excluding nested requires)   |
