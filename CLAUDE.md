# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository. The README covers the layers, rebuild, update and
Stow commands:

@README.md

## Core Commands

- **Nix rebuild**: ask user to run this, NEVER run it yourself
- **Nix validation**: `nix flake check` or `nix flake check --all-systems`
- **Nix builds**: `nix build .#darwinConfigurations.<host>.system` on Darwin
  (`zap`, `plumbus`);
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` on
  NixOS (`rpi5-homelab`, `renoir`, `wily`) — NixOS has no `.system` attribute
- **wily's private submodule**: a `.#` flake leaves submodules out, checked out
  or not, and `configuration.nix` skips the private submodule when absent, so
  such a build passes without the work config. When a change could interact with
  it, build
  `'.?submodules=1#nixosConfigurations.wily.config.system.build.toplevel'` (as
  `nh`'s flake does); in a git worktree, run
  `git submodule update --init nix/hosts/<host>/<submodule>` first
- **Format Nix files**: `nix fmt` (uses nixfmt-rfc-style)
- **CI testing**: Follow `.github/workflows/test.yml` workflow
- **Toolchain**: language toolchains and LSPs, formatters and linters come
  from `nix/shared/toolchain.nix`, which is NOT on the shell PATH: the `nvim`
  and `claude` wrappers (`stow/shared/.shell/bin/`) inject it, as does the
  devshell: `nix develop ~/.dotfiles#dev -c <cmd>` (or enter with
  `nix develop ~/.dotfiles#dev`). A project overrides a tool in its own
  `mise.toml`, whose shims come ahead of the toolchain (and which
  `mise activate` puts on the shell PATH); the global mise config
  (`stow/shared/.config/mise/config.toml`) holds settings only. A tool broken
  for every project is fixed in `toolchain.nix` (e.g. `overrideAttrs`).

## Repository Architecture

### Nix Architecture Patterns

- **Mixed stability**: servers use stable nixpkgs; desktops and laptops (NixOS
  and Darwin) use unstable. The Raspberry Pi server is anchored to the stable
  nixpkgs pinned by the `nixos-raspberrypi` input (its nixpkgs,
  `home-manager-rpi` and `disko` all follow that pin — do not make them follow
  another nixpkgs, or kernel binary cache hits are lost)
- **Module scope**: `nix/README.md` decides where a package or setting goes
  (kaizen, a shared scope, one host or one user). Read it before adding one
- **Configuration helpers**: Use `lib.mkDarwin`, `lib.mkNixos` and
  `lib.mkRpiNixos` functions from `nix/lib/`
- **Host discovery**: Configurations auto-match hostname from
  `nix/hosts/$HOSTNAME/`
- **LLM agent CLIs**: Packaged agents (claude-code, codex, gemini-cli,
  opencode, pi, ...) come from the `llm-agents` flake input
  (numtide/llm-agents.nix) and are declared via the `llmAgents` option in
  `nix/shared/home/llm-agents.nix` (mergeable across common → platform → host
  configs). Do not make this input
  follow another nixpkgs — it is built/cached against its own pin
  (cache.numtide.com)
- **No curl|bash installers in activation**: AI/agent CLIs must come from
  llm-agents (patched, cached), not native installers. Install-if-missing
  activation scripts make rebuilds depend on third-party servers.

### CLI tools outside nixpkgs

CLI tools come from nixpkgs or the `llm-agents` flake. A project needing a tool
outside nixpkgs pins it in its `mise.toml`, whose `npm:`, `pypi:`, `go:` and
`github:` backends cover tools outside mise's registry; on NixOS, nix-ld
(`nix/shared/system/linux.nix`) lets their prebuilt glibc binaries run. For a
one-off run, use `npx <pkg>` or `uvx <pkg>` from a shell instead of installing.

### niri or umbriel + Quickshell desktop (ThinkPads)

Read `kaizen/README.md` (design, map) and `kaizen/docs/development.md` (local
checks, platform boundaries, safe deployment) before changing Quickshell, niri,
umbriel or their Nix modules. `kaizen/CLAUDE.md`, symlinked into each kaizen
directory outside it, imports the README and every doc under `kaizen/docs/` when
a file there is read.

### Neovim Configuration

- Plugins are managed with `vim.pack` (no plugin-manager framework), pinned in
  `stow/shared/.config/nvim-fredrik/nvim-pack-lock.json`
- Per-language configuration lives in
  `stow/shared/.config/nvim-fredrik/plugin/lang/`
- Per-project customization via local `.nvim.lua` files (exrc), with trust
  helpers in `stow/shared/.config/nvim-fredrik/lua/exrc.lua`
- Simple setup in `stow/shared/.config/nvim-simple`, for trying out new nightly
  features and for a much simpler setup on e.g. remote shells

## Code Style Requirements

- **Nix**: 2-space indentation, follow nixpkgs conventions, use `lib.mkOption`
  for options
- **Shell**: Use `#!/usr/bin/env bash` or `#!/usr/bin/env sh`, include
  `# shellcheck shell=bash`, always add `set -e` or `set -ex` after shebang
- **Go**: 2-space tabs (not spaces), 120 char width, use gci for import
  organization
- **Python**: 4-space indentation, 88/120 char width, use ruff for formatting
  and imports
- **TypeScript**: 2-space indentation, 80 char width, prettier with prose-wrap
  always
- **QML/JS (kaizen)**: qmlformat and prettier defaults; run `qml-format` after
  editing
- **YAML**: 2-space indentation, use `---` document separator
- **Markdown**: rumdl, 80 char width with reflow; flags in
  `stow/shared/.config/nvim-fredrik/plugin/conform.lua`

## Language-Specific Tooling

For each language, consult the corresponding file in
`stow/shared/.config/nvim-fredrik/plugin/lang/` (e.g., `go.lua`, `lua.lua`,
`yaml.lua`) to get exact formatter/linter tools and configurations. Formatters
are wired up in `stow/shared/.config/nvim-fredrik/plugin/conform.lua`.

**Note**: If an LSP/formatter is not found, check that it is in
`nix/shared/toolchain.nix`, and `mise which <tool>` for a project override.

## Gotchas

- **Neovim comes from nixpkgs-unstable**, declared per host in
  `nix/hosts/<host>/users/fredrik.nix`. For a release nixpkgs lacks, override
  `neovim-unwrapped` and rewrap it with `wrapNeovim`
- **Upstream workarounds are tracked** in `kaizen/docs/issues.md`: a patch,
  override or `TODO: drop once …` for kaizen, a kaizen host or the shared
  toolchain (`nix/shared/toolchain.nix`) gets an entry
  there, with its upstream status, and loses it in the commit that drops it
