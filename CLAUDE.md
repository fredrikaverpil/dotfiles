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
  - `claude-cloud-sandbox/`: Claude cloud sandbox setup — never stowed to
    `$HOME` (install.sh only stows `shared` + platform); deployed by its own
    `bootstrap.sh` (see Claude Cloud Sandbox section)
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
- **Self-managed CLIs**: Tools with native installers that auto-update (e.g.,
  Claude Code) are declared in `selfManagedCLIs` lists at any config level
  (common, platform-specific, or user-specific)

### Self-Managed CLIs

For CLI tools that provide native installers and manage their own updates (e.g.,
Claude Code, Amp, Copilot). These are installed once on rebuild and self-update
thereafter.

- **Module**: `nix/shared/home/self-managed-clis.nix`
- **Helpers**: `mkCurlInstaller`, `mkWgetInstaller`, `mkCustomInstaller`
- **Hierarchy**: Lists merge across common → platform → user configs
- **Behavior**: Install-if-missing on each rebuild, then auto-update
  independently

Example locations:

- Cross-platform: `nix/shared/home/common.nix`
- macOS-only: `nix/shared/home/darwin.nix`
- User-specific: `nix/hosts/{hostname}/users/{username}.nix`

### Package-Managed Tools (npm and Python)

For CLI tools installed via bun (npm) or uv (Python). Unlike self-managed CLIs,
these require explicit upgrades via `./rebuild.sh --update-unstable` or
`--update`.

- **Module**: `nix/shared/home/package-tools.nix`
- **Behavior**: Installed on each rebuild; upgraded when `--update-unstable` or
  `--update` is passed to `rebuild.sh`

**Adding npm tools:**

1. Add the package to `packageTools.npmPackages` in the appropriate Nix config
2. Run `./rebuild.sh` to install
3. Update later: `./rebuild.sh --update-unstable` or `bun update -g`

**Adding Python CLI tools (via uv):**

1. Add a tool entry to `packageTools.uvTools` in the appropriate Nix config
2. Run `./rebuild.sh` to install
3. Update later: `./rebuild.sh --update-unstable` or `uv tool upgrade --all`

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

## Claude Cloud Sandbox

There are three Claude Code setups in this repo:

1. **Developer machines**: `stow/shared/.claude/` (plus platform packages),
   stowed to `~/.claude` by `./rebuild.sh --stow`
2. **Dotfiles repo scope**: root `.claude/` (settings.json, skills symlinked
   into `stow/shared/.claude/skills/`)
3. **Claude cloud sandbox**: `stow/claude-cloud-sandbox/`, symlinked as
   `.claude/sandbox/`, deployed into the sandbox's user scope (`~/.claude/`)
   by its `bootstrap.sh` — never stowed on developer machines

Sandbox-only customizations (git identity override, hooks, attribution,
skills) live in `stow/claude-cloud-sandbox/` and are installed into user
scope by `.claude/sandbox/bootstrap.sh`. Repo-level `.claude/settings.json`
hooks do NOT load when this repo is cloned side-by-side with a work repo
(only the session root's settings are read), so user scope is the only
reliable home for sandbox config.

Cloud sessions are always started with this repo selected side-by-side with
the work repo(s) — that is how the bootstrap gets onto the VM.

- **Primary (instruction to the agent)**: in a cloud sandbox session
  (`CLAUDE_CODE_REMOTE=true`), if `~/.claude/settings.json` does not
  register the sandbox hooks, immediately run
  `SANDBOX_BOOTSTRAP=1 ./.claude/sandbox/bootstrap.sh` from the dotfiles
  repo — before doing anything else, and without being asked. Hooks reload
  dynamically, so it takes effect for the rest of the session.
- **Optional hardening**: the cloud environment's setup script (configured
  once on claude.ai, stored in the environment — not in any repo) can clone
  this repo and run the bootstrap at container boot, so the hooks exist
  before the first turn instead of being installed by the agent on the
  first turn. See the header of `.claude/sandbox/bootstrap.sh` for the
  exact one-liner.

## Gotchas

- **npm packages are macOS-only**: `packageTools.npmPackages` has dynamic
  linking issues on NixOS — only add npm tools in Darwin configs
- **Neovim is managed by Bob**, not nixpkgs — binary is at
  `~/.local/share/bob/nvim-bin/nvim`
- **`stow/` changes take effect immediately** (just re-run
  `./rebuild.sh --stow`) — no Nix rebuild needed
