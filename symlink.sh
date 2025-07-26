#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$DOTFILES_DIR/stow"
cd "$STOW_DIR"

# Parse command line arguments
FORCE_MODE=false
if [[ "$1" == "--force" ]]; then
	FORCE_MODE=true
	echo "⚠️  FORCE MODE: Will overwrite existing symlinks"
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
	echo "Usage: $0 [--force]"
	echo ""
	echo "Options:"
	echo "  --force    Overwrite existing symlinks (uses stow --adopt)"
	echo "  --help     Show this help message"
	exit 0
fi

# Check if stow is installed
if ! command -v stow &>/dev/null; then
	echo "Error: GNU Stow is not installed"
	echo "Install with: brew install stow (macOS/Linux) or your package manager"
	exit 1
fi

# Detect platform
OS="$(uname -s)"
IS_MACOS="$([[ "$OS" == "Darwin" ]] && echo true || echo false)"
IS_WSL="$([[ -f /proc/version ]] && grep -qi microsoft /proc/version && echo true || echo false)"

echo "Installing dotfiles with stow..."
echo "Platform: $OS (WSL: $IS_WSL)"

# Set stow options based on force mode
STOW_OPTS="--target=$HOME --restow --verbose=1"
if [[ "$FORCE_MODE" == "true" ]]; then
	STOW_OPTS="$STOW_OPTS --adopt"
fi

# Always install shared configs
echo "Installing shared configs..."
stow $STOW_OPTS shared

# Platform-specific packages
if [[ "$IS_MACOS" == "true" ]]; then
	echo "Installing macOS-specific configs..."
	stow $STOW_OPTS macos
elif [[ "$IS_WSL" == "true" ]] || [[ "$OS" == "Linux" ]]; then
	echo "Installing Linux-specific configs..."
	stow $STOW_OPTS linux
fi

# WSL-specific handling (outside of stow)
if [[ "$IS_WSL" == "true" ]] && [[ -d "/mnt/c/Users/fredr" ]]; then
	echo "Setting up WSL config..."
	ln -sf "$DOTFILES_DIR/_windows/wslconfig" "/mnt/c/Users/fredr/.wslconfig"
fi

echo "Done!"
