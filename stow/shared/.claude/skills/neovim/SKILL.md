---
name: neovim
description: Interact with the user's running Neovim instance via RPC. Use this skill when you need to execute Lua or Vimscript inside Neovim, query buffer state, send commands, or interact with the Neovim runtime in any way. Triggers when the user asks about their current Neovim session, wants to run something inside Neovim, or when you need to inspect Neovim state (buffers, windows, options, LSP, etc.). Also use when running inside a Neovim terminal and needing to communicate with the parent editor.
---

# Neovim RPC

When Claude Code runs inside a Neovim terminal, the `$NVIM` environment variable
points to the parent Neovim's Unix socket. This gives full access to Neovim's
msgpack-RPC API without any plugins or HTTP servers.

## Prerequisites

Before sending any commands, verify the socket is available:

```bash
echo "$NVIM"
```

If `$NVIM` is empty, you are not running inside a Neovim terminal and cannot
communicate with a Neovim instance.

**Important:** When `NVIM_APPNAME` is set, all `nvim --server` commands emit a
`Warning: Using NVIM_APPNAME=...` message on **stdout** (not stderr). This
corrupts parsed output (especially JSON). To suppress it, capture the output
first, then filter:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'EXPR') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

**Note:** Piping `nvim` directly (e.g. `nvim --server "$NVIM" ... | grep ...`)
can fail because `$NVIM` may not expand correctly in pipe contexts. Always use
command substitution (`$(...)`) as shown above.

## Evaluating expressions

All examples below use the command substitution pattern from Prerequisites to
filter the `NVIM_APPNAME` warning. The shorthand `nvimx EXPR` means:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'EXPR') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

Use `--remote-expr` to evaluate a Vimscript expression and get the result back:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'v:version') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

For Lua expressions, wrap them in `luaeval()`:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.api.nvim_buf_get_name(0)")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

For multi-statement Lua that returns a value, use an IIFE:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("(function() local x = vim.api.nvim_get_current_win(); return vim.api.nvim_win_get_number(x) end)()")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

### Returning tables/lists

`luaeval()` returns Lua tables as Vimscript values. For complex data, encode as
JSON:

```bash
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.api.nvim_list_bufs())")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

## Sending commands

Use `--remote-send` to send keystrokes (as if the user typed them):

```bash
nvim --server "$NVIM" --remote-send ':echo "hello"<CR>'
```

Note: `--remote-send` does not return output and does not need the warning
filter. Use `--remote-expr` when you need a return value.

## Opening files remotely

Use `--remote` to open files in the running Neovim instance:

```bash
nvim --server "$NVIM" --remote file.txt
```

Use `--remote-tab` to open files in new tabs:

```bash
nvim --server "$NVIM" --remote-tab file1.txt file2.txt
```

## Executing Lua without a return value

To run Lua that performs side effects (no return value needed):

```bash
result=$(nvim --server "$NVIM" --remote-expr 'execute("lua vim.notify(\"Hello from Claude\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

The `execute()` Vimscript function runs an Ex command and returns its output as a
string (empty if the command produces no output).

## Common patterns

```bash
# Current buffer path
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.api.nvim_buf_get_name(0)")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# List all buffer paths (JSON)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.tbl_map(function(b) return vim.api.nvim_buf_get_name(b) end, vim.api.nvim_list_bufs()))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Current working directory
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.getcwd()")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Current cursor position [row, col] (1-indexed row)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.api.nvim_win_get_cursor(0))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Get a Neovim option value
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.o.filetype")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Check if an LSP client is attached
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr = 0})))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

## Reading help documentation

Do **not** use `execute("help ...")` — that opens help inside the editor as a
side effect instead of returning content.

First, get the key paths via RPC (do this once per session):

```bash
# Neovim data directory (plugin install root is <data>/lazy/ for lazy.nvim)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"data\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Built-in Neovim docs
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.expand(\"$VIMRUNTIME\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

Then use standard tools (`fd`, `rg`, `Glob`, `Grep`) to search and `Read` to
view the files. Search `<data>/lazy/*/doc/` for plugin docs and
`<runtime>/doc/` for built-in docs.

**Search help tags** (equivalent to `:h query<Tab>` completion):

```bash
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.fn.getcompletion(\"MiniDiff\", \"help\"))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

## Finding plugin source code

**Search runtime files** (searches all runtime paths including user config,
plugins, and `pack/*/start/*`):

```bash
# Find Lua source files matching a keyword (e.g. "codediff", "neotest")
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.api.nvim_get_runtime_file(\"lua/**/neotest*\", true))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Find any runtime file by pattern (plugin/, autoload/, syntax/, etc.)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.api.nvim_get_runtime_file(\"**/neotest*\", true))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

**Note:** `nvim_get_runtime_file` only searches **active** runtime paths.
Lazy-loaded plugins that haven't been loaded yet won't appear. See the
lazy.nvim section below for how to find those.

Then use `Read`, `Glob`, or `Grep` to explore the returned paths.

## lazy.nvim

The plugin manager [lazy.nvim](https://github.com/folke/lazy.nvim) uses its own
directory layout, separate from Neovim's built-in `pack/` structure.

### Plugin install directory

Plugins are installed under `stdpath("data")/lazy/` (e.g.
`~/.local/share/nvim-fredrik/lazy/<plugin-name>/`). This path is **not** part
of the standard Neovim `packpath`.

### Finding plugins (loaded or not)

The lazy.nvim API knows about all plugins regardless of whether they are loaded:

```bash
# Get a specific plugin's directory
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("require(\"lazy.core.config\").plugins[\"neotest\"].dir")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# List all plugins with their paths (JSON)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.json.encode(vim.tbl_map(function(p) return {name = p.name, dir = p.dir, dev = p.dev or false} end, vim.tbl_values(require(\"lazy.core.config\").plugins)))")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

You can also search the install directory directly with `fd`/`Glob` using the
`stdpath("data")/lazy/` path.

### Dev plugins (`dev = true`)

Plugins with `dev = true` in their spec are loaded from a local development
path instead of the install directory.

```bash
# Get the dev path from lazy.nvim config
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("require(\"lazy.core.config\").options.dev.path")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='

# Check if a specific plugin is using dev mode
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("require(\"lazy.core.config\").plugins[\"codediff.nvim\"].dev")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

A dev plugin's source lives at `<dev.path>/<plugin-name>` (e.g. if dev.path is
`~/code/public`, then `codediff.nvim` with `dev = true` loads from
`~/code/public/codediff.nvim`). The plugin's `.dir` field in the lazy API
already reflects this.

### Plugin specs (lazy config files)

Plugin specifications (the Lua files that configure which plugins to load) live
in the Neovim config directory, not in the install directory. Search there when
you need to find how a plugin is configured:

```bash
# Find plugin spec files
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"config\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
# Then use Glob/Grep to search the returned config path
```

## Safety

- **Never** send `:q`, `:qa`, `:bdelete`, or other destructive commands without
  explicit user confirmation.
- **Never** modify buffer contents via RPC without asking first — the user may
  have unsaved work or an undo history they care about.
- Prefer `--remote-expr` (read-only queries) over `--remote-send` (simulates
  typing) whenever possible.
- Always use command substitution + `grep -v` to suppress the `NVIM_APPNAME`
  warning (see Prerequisites).

## Workflows

For common Neovim workflows (LSP interaction, debugging, plugin management),
see the `references/` directory.
