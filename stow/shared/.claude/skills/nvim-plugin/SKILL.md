---
name: nvim-plugin
description:
  Conventions and tooling for authoring a Neovim plugin in Lua. Use when
  creating, modifying, or reviewing a plugin — plugin structure, ftplugin,
  health checks, `setup()`, vimdoc, LuaCATS, lazy loading — or when working in a
  directory that looks like one (plugin/, lua/, ftplugin/).
---

# Writing Neovim plugins

`:h lua-plugin` (https://neovim.io/doc/user/lua-plugin/) is the authority on
layout, `setup()` patterns, `<Plug>` mappings, guard variables, health checks
and deprecation. Read it rather than working from memory — it is opinionated
and it changes. This skill only records what it leaves out.

## Style

Per `.stylua.toml`: 2-space indentation, double quotes, 120-char width,
requires sorted by `stylua`.

## Tooling

- **vimdoc**: author in Markdown, generate with `panvimdoc`, then `:helptags
  doc/`.
- **Types**: annotate the public API with LuaCATS and run
  `lua-typecheck-action` in CI, so luals catches breakage before users do.
- **Releases**: SemVer via `luarocks-tag-release` or `release-please-action`.
  Publish to luarocks when the plugin has Lua dependencies or is one itself.

## Development loop

- `:restart` reloads plugin changes.
- `nvim --startuptime /tmp/nvim-startup.log` to check what eager loading in
  `plugin/` costs.
