#!/usr/bin/env bash
set -e

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Parse command line arguments
STOW_FALLBACK=false
UPDATE_FLAKE=false

while [[ $# -gt 0 ]]; do
	case $1 in
	--stow)
		STOW_FALLBACK=true
		shift
		;;
	--update)
		UPDATE_FLAKE=true
		shift
		;;
	--help | -h)
		echo "Usage: $0 [--stow] [--update]"
		echo ""
		echo "Rebuild dotfiles using Nix + Stow (default) or Stow-only mode"
		echo ""
		echo "Options:"
		echo "  --stow     Use Stow-only mode (bypass Nix, dotfiles only)"
		echo "  --update   Update flake inputs before rebuilding (Nix mode only)"
		echo "  --help     Show this help message"
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		echo "Use --help for usage information"
		exit 1
		;;
	esac
done

# Detect platform and hostname
OS="$(uname -s)"
HOSTNAME="$(hostname -s)"

echo "🚀 Rebuilding dotfiles..."
echo "Platform: $OS"
echo "Hostname: $HOSTNAME"

# Function to use Nix
use_nix() {
	echo ""
	echo "📦 Using Nix (system + packages + dotfiles via Stow)..."

	# Update flake inputs if requested
	if [[ "$UPDATE_FLAKE" == "true" ]]; then
		echo "🔄 Updating flake inputs..."
		nix flake update
		echo "✅ Flake inputs updated!"
	fi

	# Check if this hostname has a configuration
	if [[ ! -f "nix/hosts/$HOSTNAME/configuration.nix" ]]; then
		echo "❌ No Nix configuration found for hostname '$HOSTNAME'"
		echo "Available configurations:"
		find nix/hosts/ -maxdepth 1 -type d -not -path "nix/hosts/" | sed 's|nix/hosts/||' | sed 's/^/  - /' | sort
		echo ""
		echo "💡 Either:"
		echo "   1. Create nix/hosts/$HOSTNAME/configuration.nix"
		echo "   2. Use --stow for Stow-only mode"
		exit 1
	fi

	if [[ "$OS" == "Darwin" ]]; then
		echo "🍎 Found Darwin configuration for $HOSTNAME"
		sudo darwin-rebuild switch --flake ".#$HOSTNAME"
	elif [[ "$OS" == "Linux" ]]; then
		echo "🐧 Found NixOS configuration for $HOSTNAME"
		sudo nixos-rebuild switch --flake ".#$HOSTNAME"
	else
		echo "❌ Unsupported platform for Nix: $OS"
		echo "💡 Use --stow for Stow-only mode"
		exit 1
	fi
}

# Function to use GNU Stow
use_stow() {
	echo ""
	echo "🔗 Using Stow-only mode (dotfiles only, no system changes)..."
	cd stow
	./install.sh
}

# Main logic
if [[ "$STOW_FALLBACK" == "true" ]]; then
	use_stow
elif command -v nix &>/dev/null; then
	use_nix
else
	echo "⚠️  Nix not found, using Stow-only mode..."
	use_stow
fi

echo ""
echo "✅ Dotfiles rebuild complete!"
