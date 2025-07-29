#!/usr/bin/env bash
set -e

# Get the directory where this script is located
STOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$STOW_DIR"

# Check if stow is installed
if ! command -v stow &>/dev/null; then
	echo "Error: GNU Stow is not installed"
	echo "Install with: brew install stow (macOS/Linux) or your package manager"
	exit 1
fi

# Auto-detect platform and packages
OS="$(uname -s)"
PACKAGES=("shared")

# Add platform-specific package if it exists
if [[ -d "$OS" ]]; then
    PACKAGES+=("$OS")
fi

echo "Installing dotfiles for platform: $OS"
echo "Packages: ${PACKAGES[*]}"

# Clean existing symlinks
echo "Cleaning existing symlinks..."
for pkg in "${PACKAGES[@]}"; do
    stow --target="$HOME" --delete "$pkg" 2>/dev/null || true
done

# Install packages
for pkg in "${PACKAGES[@]}"; do
    echo "Installing $pkg configs..."
    if ! stow --target="$HOME" --restow --verbose=1 "$pkg"; then
        echo "Error: Failed to install $pkg configs"
        exit 1
    fi
done

echo "✅ Dotfiles installation complete!"