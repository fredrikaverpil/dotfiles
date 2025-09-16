# Agent Guidelines for Fredrik's Dotfiles

This file provides guidance to AI agents when working with code in this
repository.

## Core Commands

- **Symlink dotfiles**: `./rebuild.sh --stow` (GNU Stow dotfiles without Nix
  rebuild)
- **Nix rebuild**: ask user to run this, NEVER run it yourself
- **Nix validation**: `nix flake check` or `nix flake check --all-systems`
- **Nix builds**: `nix build .#darwinConfigurations.<host>.system`
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
- `nvim-fredrik/`: Complete Neovim configuration with modular per-language setup
- `shell/`: Shell configuration, aliases, and custom scripts
- `flake.nix`: Main Nix flake defining system configurations and package sources

### Nix Architecture Patterns

- **Mixed stability**: Darwin uses unstable nixpkgs, Linux uses stable (25.05)
- **Configuration helpers**: Use `lib.mkDarwin` and `lib.mkNixos` functions from
  `nix/lib/`
- **Host discovery**: Configurations auto-match hostname from
  `nix/hosts/$HOSTNAME/`
- **Package management**: CLI tools via Nix, GUI apps via Homebrew (macOS) or
  Nix (Linux)

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

## Error Handling

- Shell scripts should use `set -e` for fail-fast behavior and Nix compatibility
- Go: Use explicit error handling, avoid panic in libraries
- Python: Use proper exception handling, type hints preferred
- All languages: Validate inputs with meaningful error messages
