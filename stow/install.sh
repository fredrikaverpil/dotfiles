#!/usr/bin/env bash
set -e

# Get the directory where this script is located
STOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$STOW_DIR"

# Parse command line arguments
STOW_FLAGS=()
while [[ $# -gt 0 ]]; do
	case $1 in
	--adopt)
		# Absorb a conflicting real file's content into the stow package
		# (overwriting it), then symlink as usual. Use when some tool replaced
		# a symlinked config with a real file. Review with `git diff` before
		# committing -- nothing is staged or committed automatically.
		STOW_FLAGS+=(--adopt)
		shift
		;;
	--help | -h)
		echo "Usage: $0 [--adopt]"
		echo ""
		echo "  --adopt  Absorb conflicting real files into the stow package instead"
		echo "           of aborting (review with 'git diff' before committing)"
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

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
    if ! stow --target="$HOME" --simulate --restow --no-folding "${STOW_FLAGS[@]}" "$pkg" 2>&1; then
        echo "Error: Conflict detected in $pkg — aborting before making any changes"
        echo "If a real file exists where a symlink should be, re-run with: ./install.sh --adopt"
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
    if ! stow --target="$HOME" --restow --no-folding --verbose=1 "${STOW_FLAGS[@]}" "$pkg"; then
        echo "Error: Failed to install $pkg configs"
        exit 1
    fi
done

echo "✅ Dotfiles installation complete!"
if [[ " ${STOW_FLAGS[*]} " == *" --adopt "* ]]; then
    echo "Adopted files now hold their previous on-disk content -- run 'git diff' and review before committing."
fi
