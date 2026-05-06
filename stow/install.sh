#!/usr/bin/env bash
set -e

# Get the directory where this script is located
STOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$STOW_DIR"

# Check if stow is installed
if ! command -v stow &>/dev/null; then
	echo "Error: GNU Stow is not installed"
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

# Simulate first to catch conflicts before touching anything
echo "Checking for conflicts..."
for pkg in "${PACKAGES[@]}"; do
    if ! stow --target="$HOME" --simulate --restow --no-folding "$pkg" 2>&1; then
        echo "Error: Conflict detected in $pkg — aborting before making any changes"
        exit 1
    fi
done

# Clean existing symlinks
echo "Cleaning existing symlinks..."
for pkg in "${PACKAGES[@]}"; do
    stow --target="$HOME" --delete "$pkg" 2>/dev/null || true
done

# Install packages
for pkg in "${PACKAGES[@]}"; do
    echo "Installing $pkg configs..."
    if ! stow --target="$HOME" --restow --no-folding --verbose=1 "$pkg"; then
        echo "Error: Failed to install $pkg configs"
        exit 1
    fi
done

echo "✅ Dotfiles installation complete!"
