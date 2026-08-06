# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Core Commands

- **Full rebuild (Darwin)**: `sudo darwin-rebuild switch --flake
  ~/.dotfiles#"$(hostname -s)"` (hosts: `zap`, `plumbus`)
- **Full rebuild (NixOS)**: `sudo nixos-rebuild switch --flake
  ~/.dotfiles#"$(hostname -s)"` (host: `rpi5-homelab`)
- **Symlink dotfiles only**: `cd ~/.dotfiles/stow && stow --target="$HOME"
  --restow --no-folding --adopt shared "$(uname -s)"` (GNU Stow, no Nix rebuild)
- **Update all flake inputs**: `nix flake update`, then rebuild
- **Update only unstable-pinned inputs**: `nix flake update nixpkgs-unstable
  nix-darwin home-manager-unstable llm-agents dotfiles`, then rebuild
- **Refresh package-managed CLI tools after an update**: `uv tool upgrade --all`
  and `npm-tools-upgrade`
- **Nix rebuild**: ask user to run this, NEVER run it yourself
- **Nix validation**: `nix flake check` or `nix flake check --all-systems`
- **Nix builds**: `nix build .#darwinConfigurations.<host>.system` (hosts:
  `zap`, `plumbus` on Darwin; `rpi5-homelab` on NixOS)
- **Format Nix files**: `nix fmt` (uses nixfmt-rfc-style)
- **CI testing**: Follow `.github/workflows/test.yml` workflow
- **Toolchain outside Neovim**: language toolchains (go, python3, node, ruby,
  rustup, elixir, tree-sitter, ...) are NOT on the base PATH — `shell/bin/nvim`
  injects them into Neovim only. When running outside Neovim (e.g. Claude Code
  under Remote Control) and needing them, use the devshell:
  `nix develop ~/.dotfiles#dev -c <cmd>` (or enter with
  `nix develop ~/.dotfiles#dev`). Defined once in `nix/shared/toolchain.nix`,
  shared by the devshell and Neovim's `nvim-deps-path`.

### Verifying a Darwin rebuild actually landed

home-manager's per-user activation on macOS can silently no-op
(home-manager#4413). `nix/shared/system/darwin.nix` guards against it with a
verify-or-retry `postActivation` step. To check manually, compare the
home-manager gcroot (`readlink
~/.local/state/home-manager/gcroots/current-home`) against the expected
generation — `readlink /run/current-system` updates even on a silent miss, so
it proves nothing.

## Repository Architecture

This is a dotfiles repository using **Nix flakes** for system/package management
and **GNU Stow** for dotfile symlinking.

### Nix Architecture Patterns

- **Mixed stability**: Darwin uses unstable nixpkgs; the Raspberry Pi is
  anchored to the nixpkgs pinned by the `nixos-raspberrypi` input (its
  nixpkgs, `home-manager-rpi` and `disko` all follow that pin — do not make
  them follow another nixpkgs, or kernel binary cache hits are lost)
- **Configuration helpers**: Use `lib.mkDarwin` and `lib.mkRpiNixos` functions
  from `nix/lib/`
- **Host discovery**: Configurations auto-match hostname from
  `nix/hosts/$HOSTNAME/`
- **Package management**: CLI tools via Nix, GUI apps via Homebrew (macOS) or
  Nix (Linux)
- **LLM agent CLIs**: Packaged agents (claude-code, codex, gemini-cli,
  opencode, pi, ...) come from the `llm-agents` flake input
  (numtide/llm-agents.nix) and are declared via `packageTools.llmAgents`
  (mergeable across common → platform → host configs). Do not make this input
  follow another nixpkgs — it is built/cached against its own pin
  (cache.numtide.com). Update via `nix flake update llm-agents`, then rebuild
- **No curl|bash installers in activation**: AI/agent CLIs must come from
  llm-agents (patched, cached), not native installers. Prebuilt glibc
  binaries cannot run on NixOS (stub-ld), and install-if-missing activation
  scripts make rebuilds depend on third-party servers.

### Package-Managed Tools (npm and Python)

For CLI tools installed via deno (npm) or uv (Python). These require an
explicit `uv tool upgrade --all` / `npm-tools-upgrade` after updating flake
inputs to actually pick up new versions.

- **Module**: `nix/shared/home/package-tools.nix`
- **Behavior**: Installed on each rebuild; upgraded manually via
  `uv tool upgrade --all` / `npm-tools-upgrade`

To add a tool, add an entry to `packageTools.npmPackages` (a `{ package, bin }`
pair), `packageTools.uvTools`, or `packageTools.llmAgents` (a package name from
the `llm-agents` flake) at the appropriate config level, then rebuild.

### Neovim Configuration

- Plugins are managed with `vim.pack` (no plugin-manager framework), pinned in
  `nvim-fredrik/nvim-pack-lock.json`
- Per-language configuration lives in `nvim-fredrik/plugin/lang/`
- Per-project customization via local `.nvim.lua` files (exrc), with trust
  helpers in `nvim-fredrik/lua/exrc.lua`
- Simple setup in `nvim-simple`, for trying out new nightly features and for a
  much simpler setup on e.g. remote shells

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
- **YAML**: 2-space indentation, use `---` document separator

## Language-Specific Tooling

For each language, consult the corresponding file in
`nvim-fredrik/plugin/lang/` (e.g., `go.lua`, `lua.lua`, `yaml.lua`) to get
exact formatter/linter tools and configurations. Formatters are wired up in
`nvim-fredrik/plugin/conform.lua`.

**Note**: If LSP/formatter not found, check Mason install path:
`~/.local/share/nvim-fredrik/mason/bin/` or `~/.local/share/nvim/mason/bin/`

## Gotchas

- **Neovim is managed by Bob**, not nixpkgs — binary is at
  `~/.local/share/bob/nvim-bin/nvim`
- **`stow/` changes take effect immediately** (just re-run
  `cd ~/.dotfiles/stow && stow --target="$HOME" --restow --no-folding --adopt
  shared "$(uname -s)"`) — no Nix rebuild needed
