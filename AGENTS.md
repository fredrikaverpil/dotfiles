# Agent Guidelines for Fredrik's Dotfiles

## Build/Test/Lint Commands

- **Install dotfiles**: `./rebuild.sh` (uses Nix + GNU Stow automatically)
- **Stow-only mode**: `./rebuild.sh --stow` (bypasses Nix, dotfiles only)
- **Force update**: `./rebuild.sh --update` (updates flake inputs)
- **CI testing**: Follow `.github/workflows/test.yml` workflow
- **Nix operations**: `nix flake check`,
  `nix build .#darwinConfigurations.<host>.system`

## Language-Specific Formatting/Linting

- See `nvim-fredrik/lua/fredrik/plugins/lang/*.lua` for specific
  formatter/linter tools and configurations
- For each language, read the corresponding file (e.g., `go.lua`, `python.lua`,
  `typescript.lua`) to get exact tools and arguments
- **Testing**: Run tests if changes can be tested (check README or search
  codebase to determine testing approach)
- **Related tools**: Run relevant validation commands (e.g., `nix flake check`
  for Nix changes)
- **Note**: If LSP/formatter not found, check Mason install path:
  `~/.local/share/fredrik/mason/bin/` or `~/.local/share/nvim/mason/bin/`

## Code Style Guidelines

- **Go**: 2-space tabs (not spaces), 120 char width, use gci for import
  organization
- **Python**: 4-space indentation, 88/120 char width, use ruff for formatting
  and imports
- **TypeScript**: 2-space indentation, 80 char width, prettier with prose-wrap
  always
- **Shell**: Use `#!/usr/bin/env bash` or `#!/usr/bin/env sh`, include
  `# shellcheck shell=bash`, always add `set -e` or `set -ex` after shebang
- **Rust**: Follow rustfmt defaults, use clippy suggestions
- **Lua**: 2-space indentation, double quotes preferred, 120 char width, sort
  requires
- **Nix**: 2-space indentation, follow nixpkgs conventions, use `lib.mkOption`
  for options
- **YAML**: 2-space indentation, use `---` document separator

## Repository Structure

- `stow/`: Stow packages for dotfile symlinking
  - `shared/`: Cross-platform dotfiles
  - `Darwin/`: macOS-specific dotfiles
  - `Linux/`: Linux-specific dotfiles (including WSL)
- `shell/`: Shell config, aliases, bin scripts
- `nix/`: Nix/NixOS configurations per host
- `nvim-fredrik/`: Neovim configuration
- `installers/`: Tool installation scripts

## Error Handling

- Shell scripts should use `set -e` for fail-fast behavior
- Go: Use explicit error handling, avoid panic in libraries
- Python: Use proper exception handling, type hints preferred
- All languages: Validate inputs with meaningful error messages

