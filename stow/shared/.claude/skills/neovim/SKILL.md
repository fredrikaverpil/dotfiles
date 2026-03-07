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
# Plugin docs directory (lazy.nvim plugins)
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.stdpath(\"data\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
# e.g. ~/.local/share/nvim-fredrik -> plugin docs at <data>/lazy/*/doc/

# Built-in Neovim docs
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("vim.fn.expand(\"$VIMRUNTIME\")")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
# e.g. -> built-in docs at <runtime>/doc/
```

Then use standard tools to search and read:

```bash
# Find doc files by name (using Glob or fd)
fd 'diff.*\.txt$' ~/.local/share/nvim-fredrik/lazy --type f

# Search doc content for a specific topic (using Grep or rg)
rg -l "toggle_overlay" ~/.local/share/nvim-fredrik/lazy/*/doc/

# Search built-in docs
rg "foldmethod" ~/.local/share/bob/nightly/share/nvim/runtime/doc/
```

Then read matching files with the `Read` tool.

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

**Exact plugin path** (via lazy.nvim API, when the plugin name is known):

```bash
result=$(nvim --server "$NVIM" --remote-expr 'luaeval("require(\"lazy.core.config\").plugins[\"neotest\"].dir")') && echo "$result" | grep -v '^Warning: Using NVIM_APPNAME='
```

**Note:** `nvim_get_runtime_file` only searches **active** runtime paths.
Lazy-loaded plugins that haven't been loaded yet won't appear. For those, use
the lazy.nvim API or search `stdpath("data")/lazy/` directly with `fd`/`Glob`.
The `/lazy/` subdirectory is specific to the lazy.nvim plugin manager.

Then use `Read`, `Glob`, or `Grep` to explore the returned paths.

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
