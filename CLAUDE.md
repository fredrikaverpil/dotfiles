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
- **wily in a git worktree**: submodules aren't checked out, and
  `configuration.nix` skips `einride/` when absent, so a build there passes
  without the work config. Run `git submodule update --init
  nix/hosts/wily/einride` first when a change could interact with it
- **Format Nix files**: `nix fmt` (uses nixfmt-rfc-style)
- **CI testing**: Follow `.github/workflows/test.yml` workflow
- **Toolchain outside Neovim**: language toolchains (go, python3, node, ruby,
  rustup, elixir, tree-sitter, ...) are NOT on the base PATH —
  `stow/shared/.shell/bin/nvim` injects them into Neovim only. When running
  outside Neovim (e.g. Claude Code under Remote Control) and needing them, use
  the devshell: `nix develop ~/.dotfiles#dev -c <cmd>` (or enter with
  `nix develop ~/.dotfiles#dev`). Defined once in `nix/shared/toolchain.nix`,
  shared by the devshell and Neovim's `nvim-deps-path`.

## Repository Architecture

### Nix Architecture Patterns

- **Mixed stability**: Darwin uses unstable nixpkgs; the Raspberry Pi is
  anchored to the nixpkgs pinned by the `nixos-raspberrypi` input (its
  nixpkgs, `home-manager-rpi` and `disko` all follow that pin — do not make
  them follow another nixpkgs, or kernel binary cache hits are lost)
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
  llm-agents (patched, cached), not native installers. Prebuilt glibc
  binaries cannot run on NixOS (stub-ld), and install-if-missing activation
  scripts make rebuilds depend on third-party servers.

### CLI tools outside nixpkgs

There is no mechanism for installing CLI tools with a language package manager
(npm, uv, ...) — a tool must come from nixpkgs or the `llm-agents` flake.
Wheels and prebuilt npm binaries are glibc-linked and fail to load on NixOS
(`libstdc++.so.6: cannot open shared object file`). For a one-off run, use
`npx <pkg>` or `uvx <pkg>` from a shell instead of installing.

### niri + Quickshell desktop (ThinkPads)

Read `docs/kaizen/README.md` (design, map) and `docs/kaizen/development.md`
(local checks, platform boundaries, safe deployment) before changing
Quickshell, niri or their Nix modules. A `CLAUDE.md` symlink in each kaizen
directory imports both when a file there is read.

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

**Note**: If LSP/formatter not found, check Mason install path:
`~/.local/share/nvim-fredrik/mason/bin/` or `~/.local/share/nvim/mason/bin/`

## Gotchas

- **Neovim comes from nixpkgs-unstable**, declared per host in
  `nix/hosts/<host>/users/fredrik.nix`. For a release nixpkgs lacks, override
  `neovim-unwrapped` and rewrap it with `wrapNeovim`
