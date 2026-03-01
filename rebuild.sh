#!/usr/bin/env bash
set -e

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Parse command line arguments
STOW_FALLBACK=false
UPDATE_FLAKE=false
UPDATE_UNSTABLE=false

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
	--update-unstable)
		UPDATE_UNSTABLE=true
		shift
		;;
	--help | -h)
		echo "Usage: $0 [--stow] [--update] [--update-unstable]"
		echo ""
		echo "Rebuild dotfiles using Nix + Stow (default) or Stow-only mode"
		echo ""
		echo "Options:"
		echo "  --stow             Use Stow-only mode (bypass Nix, dotfiles only)"
		echo "  --update           Update ALL flake inputs + uv tools + bun packages before rebuilding"
		echo "  --update-unstable  Update unstable flake inputs + uv tools + bun packages before rebuilding"
		echo "  --help             Show this help message"
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

	# Update all flake inputs if requested
	if [[ "$UPDATE_FLAKE" == "true" ]]; then
		echo "🔄 Updating all flake inputs..."
		nix flake update
		echo "✅ All flake inputs updated!"
	# Update only unstable inputs if requested
	elif [[ "$UPDATE_UNSTABLE" == "true" ]]; then
		echo "🔄 Updating unstable inputs..."
		nix flake update nixpkgs-unstable nix-darwin home-manager-unstable dotfiles
		echo "✅ Unstable inputs updated!"
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

	# Upgrade package-managed tools when updating (after rebuild so uv/bun are available)
	if [[ "$UPDATE_FLAKE" == "true" || "$UPDATE_UNSTABLE" == "true" ]]; then
		if command -v uv &>/dev/null; then
			echo ""
			echo "🐍 Upgrading uv tools..."
			uv tool upgrade --all
		fi

		if command -v bun &>/dev/null; then
			echo ""
			echo "📦 Upgrading npm packages..."
			bun update -g
		fi
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
