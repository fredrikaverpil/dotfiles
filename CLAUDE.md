# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Core Commands

- **Full rebuild**: `./rebuild.sh` (Nix rebuild + Stow, reproducible by default)
- **Update unstable inputs**: `./rebuild.sh --update-unstable` (then rebuild)
- **Update all inputs**: `./rebuild.sh --update` (then rebuild)
- **Symlink dotfiles only**: `./rebuild.sh --stow` (GNU Stow without Nix
  rebuild)
- **Nix rebuild**: ask user to run this, NEVER run it yourself
- **Nix validation**: `nix flake check` or `nix flake check --all-systems`
- **Nix builds**: `nix build .#darwinConfigurations.<host>.system` (hosts:
  `zap`, `plumbus` on Darwin; `rpi5-homelab` on NixOS)
- **Format Nix files**: `nix fmt` (uses nixfmt-rfc-style)
- **CI testing**: Follow `.github/workflows/test.yml` workflow

## Repository Architecture

This is a dotfiles repository using **Nix flakes** for system/package management
and **GNU Stow** for dotfile symlinking.

### Key Structure

- `nix/`: Nix configurations organized by host and shared components
  - `hosts/`: Per-host configurations (system settings, hardware configs, users)
  - `shared/`: Cross-platform shared configurations (home, system, overlays)
  - `lib/`: Helper functions for system/user configuration generation
- `stow/`: GNU Stow packages for dotfile symlinking
  - `shared/`: Cross-platform dotfiles
  - `Darwin/`: macOS-specific dotfiles
  - `Linux/`: Linux-specific dotfiles
- `extras/`: One-off platform-specific extras, legacy configs, and additional
  READMEs
- `nvim-fredrik/`: Complete Neovim configuration with modular per-language setup
- `shell/`: Shell configuration, aliases, and custom scripts
- `flake.nix`: Main Nix flake defining system configurations and package sources

### Nix Architecture Patterns

- **Mixed stability**: Darwin uses unstable nixpkgs; the Raspberry Pi is
  anchored to the nixpkgs pinned by the `nixos-raspberrypi` input (its
  nixpkgs, `home-manager-rpi` and `disko` all follow that pin — do not make
  them follow another nixpkgs, or kernel binary cache hits are lost)
- **Configuration helpers**: Use `lib.mkDarwin` and `lib.mkRpiNixos` functions from
  `nix/lib/`
- **Host discovery**: Configurations auto-match hostname from
  `nix/hosts/$HOSTNAME/`
- **Package management**: CLI tools via Nix, GUI apps via Homebrew (macOS) or
  Nix (Linux)
- **LLM agent CLIs**: Packaged agents (claude-code, codex, gemini-cli,
  kimi-code, opencode, pi, ...) come from the `llm-agents` flake input
  (numtide/llm-agents.nix) and are declared via `packageTools.llmAgents`
  (mergeable across common → platform → host configs). Do not make this input
  follow another nixpkgs — it is built/cached against its own pin
  (cache.numtide.com). Update via `./rebuild.sh --update-unstable`
- **No curl|bash installers in activation**: AI/agent CLIs must come from
  llm-agents (patched, cached), not native installers. Prebuilt glibc
  binaries cannot run on NixOS (stub-ld), and install-if-missing activation
  scripts make rebuilds depend on third-party servers.

### Package-Managed Tools (npm and Python)

For CLI tools installed via deno (npm) or uv (Python). These require explicit
upgrades via `./rebuild.sh --update-unstable` or `--update`.

- **Module**: `nix/shared/home/package-tools.nix`
- **Behavior**: Installed on each rebuild; upgraded when `--update-unstable` or
  `--update` is passed to `rebuild.sh`

**Adding npm tools:**

1. Add a `{ package, bin }` entry to `packageTools.npmPackages` in the
   appropriate Nix config (`bin` is the package.json "bin" name)
2. Run `./rebuild.sh` to install
3. Update later: `./rebuild.sh --update-unstable` or `npm-tools-upgrade`

**Adding Python CLI tools (via uv):**

1. Add a tool entry to `packageTools.uvTools` in the appropriate Nix config
2. Run `./rebuild.sh` to install
3. Update later: `./rebuild.sh --update-unstable` or `uv tool upgrade --all`

**Adding LLM agent CLIs:**

1. Add the package name (an attribute of the llm-agents flake's `packages`,
   e.g. `"claude-code"`) to `packageTools.llmAgents` at the appropriate config
   level (common, platform, or host user config)
2. Run `./rebuild.sh` to install
3. Update later: `./rebuild.sh --update-unstable`

### Neovim Configuration

- Modular setup with per-language configurations in
  `nvim-fredrik/lua/fredrik/plugins/lang/`
- Plugin loading order: generic plugins → language-specific → core → local
  overrides
- Per-project customization via local `.lazy.lua` files
- Simple setup in `nvim-simple`, for trying out new nightly features and for a
  much simpler setup on e.g. remote shells

## Development Workflow

1. **Making changes**: Edit files in `stow/` for dotfiles, `nix/` for system
   configs
2. **Testing**: Run `nix flake check` for Nix validation
3. **Applying**: ALWAYS ask the user to apply, NEVER apply yourself
4. **Language tools**: Check `nvim-fredrik/lua/fredrik/plugins/lang/*.lua` for
   formatter/linter configs

## Code Style Requirements

- **Nix**: 2-space indentation, follow nixpkgs conventions, use `lib.mkOption`
  for options
- **Shell**: Use `#!/usr/bin/env bash` or `#!/usr/bin/env sh`, include
  `# shellcheck shell=bash`, always add `set -e` or `set -ex` after shebang
- **Lua**: 2-space indentation, double quotes preferred, 120 char width, sort
  requires (per `.stylua.toml`)
- **Go**: 2-space tabs (not spaces), 120 char width, use gci for import
  organization
- **Python**: 4-space indentation, 88/120 char width, use ruff for formatting
  and imports
- **TypeScript**: 2-space indentation, 80 char width, prettier with prose-wrap
  always
- **Rust**: Follow rustfmt defaults, use clippy suggestions
- **YAML**: 2-space indentation, use `---` document separator

## Language-Specific Tooling

For each language, consult the corresponding file in
`nvim-fredrik/lua/fredrik/plugins/lang/` (e.g., `go.lua`, `python.lua`,
`typescript.lua`) to get exact formatter/linter tools and configurations.

**Note**: If LSP/formatter not found, check Mason install path:
`~/.local/share/nvim-fredrik/mason/bin/` or `~/.local/share/nvim/mason/bin/`

## Gotchas

- **Neovim is managed by Bob**, not nixpkgs — binary is at
  `~/.local/share/bob/nvim-bin/nvim`
- **`stow/` changes take effect immediately** (just re-run
  `./rebuild.sh --stow`) — no Nix rebuild needed
