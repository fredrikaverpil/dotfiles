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

echo "Installing dotfiles with stow..."
echo "Platform: $OS"

# Set stow options based on force mode
STOW_OPTIONS="--target=$HOME --restow --verbose=1"
if [[ "$FORCE_MODE" == "true" ]]; then
	STOW_OPTIONS="$STOW_OPTIONS --adopt"
fi

# Always install shared configs
echo "Installing shared configs..."
stow $STOW_OPTIONS shared

# Platform-specific packages
if [[ "$OS" == "Darwin" ]]; then
	echo "Installing macOS-specific configs..."
	stow $STOW_OPTIONS macos
elif [[ "$OS" == "Linux" ]]; then
	echo "Installing Linux-specific configs..."
	stow $STOW_OPTIONS linux
fi

echo "Done!"
