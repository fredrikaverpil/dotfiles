# Lua LSP setup notes

Why `after/lsp/lua_ls.lua` and `plugin/lang/lua.lua` contain a few non-obvious
lines, and how LuaLS + lazydev.nvim interact.

Investigated 2026-08-05 against a Lua plugin repo (`neotest-golang`) — a repo
whose own modules live under `lua/` and require each other.

## Symptoms

In a Lua plugin repo:

1. `gr` (references) on a module-level function such as `M.golist_data` in
   `lua/neotest-golang/lib/cmd.lua` returned nothing — snacks reported
   "No results found for lsp_references".
2. `gd` on `neotest.Position` went nowhere.
3. `Undefined global vim` on ordinary `vim.system(...)` calls.
4. LuaLS indexing thousands of files from vendored directories.

## The three independent causes

### 1. lazydev's `lua_root` mode breaks intra-project `require()`

By default lazydev registers `<root>/lua` as a LuaLS **library**, adds `/lua` to
`workspace.ignoreDir`, and sets `runtime.path = { "?.lua", "?/init.lua" }`.

In this repo LuaLS then never resolved `require("neotest-golang.lib")`. Hovering
`lib` showed a shape inferred from usage rather than the real module:

```lua
(upvalue) lib: { cmd: unknown, convert: unknown, extra_args: unknown, ... }
```

Every `lib.cmd.golist_data` was a dead end, so references returned 1 (only the
declaration), which snacks then filtered out — hence "No results found".

Fix (`plugin/lang/lua.lua`):

```lua
require("lazydev.config").lua_root = false
```

That switches lazydev to `runtime.path = { "lua/?.lua", "lua/?/init.lua" }`,
which resolves correctly. It is not exposed through `setup()` — `lua_root` is a
plain field on `lazydev.config`, set outside the `defaults` table, so the
metatable never consults anything passed to `setup()`. Hence the direct
assignment.

Measured: references on `M.golist_data` go from **1** to **16**.

### 2. LuaLS only scans `workspace.library` during startup

This is the important one, and it is easy to misdiagnose because LuaLS *accepts*
the configuration without complaint.

LuaLS's own log (`<mason>/packages/lua-language-server/libexec/log/`) shows
`Scan library at:` firing **only** for LuaLS's builtin LuaJIT meta files. The
nvim runtime, neotest and plenary paths appear in the config LuaLS logged
receiving — they are simply never scanned, because lazydev pushes them after
`initialize` via `workspace/didChangeConfiguration`.

This is why references worked while types did not: references only need
`runtime.path`, which does apply late. Globals and `---@class` declarations need
the library files to actually be **loaded**.

Fix (`after/lsp/lua_ls.lua`):

```lua
workspace = {
  checkThirdParty = false,
  library = vim.api.nvim_get_runtime_file("", true),
},
```

Seeding it in the server config means it is present in `client.settings` before
LuaLS's first `workspace/configuration` pull, so it gets scanned at startup.
lazydev's later additions still compose on top — its handler builds its response
from a deepcopy of `client.settings`.

**Caveats:**

- `nvim_get_runtime_file("", true)` is evaluated when the lua_ls config is
  resolved. A plugin loaded *after* the first Lua buffer opens will not be in
  that seed. lazydev still adds those dynamically; they just miss the startup
  scan.
- nvim-lspconfig's own docs warn that pulling in all of `runtimepath` this way
  is "a lot slower and will cause issues when working on your own
  configuration" — see [nvim-lspconfig#3189][1]. That is the trade being made
  here: correctness over startup cost. Revisit if editing the Neovim config
  itself starts misbehaving.

[1]: https://github.com/neovim/nvim-lspconfig/issues/3189

### 3. Vendored directories, and why `.gitignore` is not enough

`workspace.useGitIgnore` defaults to `true`, but LuaLS reads only the
**workspace-root** `.gitignore` — it does not walk nested ones. In this repo
`.pocket/tools` was ignored solely by `.pocket/.gitignore`, so LuaLS indexed it:
three complete Neovim distributions under `.pocket/tools/neovim/`, contributing
**11,648** symbols against 60 from the actual project. Every `vim.*` lookup
offered four candidates.

More importantly: once the library is seeded (cause 2), LuaLS scans the
workspace far more aggressively and gitignored directories come back regardless
— `.pocket` and `.tests` reappeared with 2,158 and 727 symbols even though both
are listed in the root `.gitignore`.

So the exclusion has to be explicit, per project, in `.luarc.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime.version": "LuaJIT",
  "workspace.checkThirdParty": false,
  "workspace.ignoreDir": [".pocket", ".tests", ".venv", "site"]
}
```

## `.luarc.json` and lazydev

**`.luarc.json` takes precedence over settings sent by the client, and it
replaces per key rather than merging.** lazydev warns about this itself (visible
in `:LazyDev` debug output).

Never put `workspace.library` in a project `.luarc.json` — it clobbers lazydev's
entire list. `workspace.ignoreDir` is safe **only because** `lua_root = false`
makes lazydev set `ignoreDir = nil`, so nothing overwrites it. If `lua_root`
were left at its default, lazydev would write `ignoreDir = { "/lua" }` and the
two would fight.

Keys that merely restate what lazydev already sets — `runtime.version`,
`workspace.checkThirdParty` — are harmless, and worth keeping in a shared
repo's `.luarc.json` for contributors who do not configure `lua_ls` themselves.

### The trade-off in a shared repo

nvim-lspconfig ships **no `on_init`** for `lua_ls`. The `on_init` snippet in
`lsp/lua_ls.lua` is inside a doc comment — an example, not a default. Its real
config is only `cmd`, `filetypes`, `root_markers`, `codeLens` and `hint`.

So in a repo like `neotest-golang`, `workspace.library` in `.luarc.json` is the
*only* thing giving `$VIMRUNTIME` to a contributor who runs neither lazydev nor
their own library config. Removing it fixes lazydev users and regresses those
contributors to `Undefined global vim`:

| `.luarc.json` | lazydev users | plain lspconfig, no lazydev |
| --- | --- | --- |
| with `workspace.library: ["$VIMRUNTIME"]` | lose plugin typings | `vim` globals work |
| without | everything resolves | lose `vim` globals |

There is no setting that satisfies both, because the file replaces rather than
merges. The durable fix belongs in the editor config (seed the library there),
not in the repo — which is what `after/lsp/lua_ls.lua` now does.

Tracked in [fredrikaverpil/neotest-golang#590][2].

[2]: https://github.com/fredrikaverpil/neotest-golang/pull/590

## Verifying

Drive a headless Neovim over RPC rather than eyeballing it; pushed diagnostics
can lag, so prefer pull requests (`textDocument/references`,
`textDocument/definition`) as the source of truth.

```lua
-- open a file, wait for lua_ls, then:
c:request_sync("textDocument/references", {
  textDocument = { uri = U },
  position = { line = 19, character = 15 },
  context = { includeDeclaration = true },
}, 20000, bufnr)
```

`workspace/symbol` bucketed by URI prefix is a good way to see what is actually
indexed and from where.

Known-good result in `neotest-golang`:

| Check | Expected |
| --- | --- |
| references on `lib.cmd.golist_data` | 16 |
| `gd` on `neotest.Position` | `neotest/lua/neotest/types/init.lua` |
| `gd` on `vim.system` | `lua/vim/_core/system.lua` |
| symbols from `.pocket` / `.tests` | 0 |

## Dead ends

Recorded so they are not re-tried:

- **Deleting `.luarc.json` alone** does not fix references. An early run
  suggested it did; it was not reproducible.
- **Clearing lazydev's `ignoreDir` while keeping `lua_root = true`** does not
  fix references.
- **Adding `.pocket/tools` to the root `.gitignore`** works only until the
  library is seeded, after which the directory is indexed again anyway.
- **Appending `/lua` to library paths by hand** changes nothing — with
  `lua_root = false` the plugin root is the correct shape.
- **`maxPreload`** is not involved; `$VIMRUNTIME` holds only ~188 Lua files.

## Unrelated bug found along the way

`lazydev.setup({ library = { ... } })` took `"plenary"`, but the plugin
directory is `plenary.nvim`. `Pkg.get_plugin_path` failed to resolve it and the
literal string `"plenary"` was passed through into `workspace.library`. Now
`"plenary.nvim"`. Library entries must match the plugin directory name.
