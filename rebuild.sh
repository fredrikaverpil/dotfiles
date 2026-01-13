#!/usr/bin/env bash
set -e

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Parse command line arguments
STOW_FALLBACK=false
UPDATE_FLAKE=false
UPDATE_UNSTABLE=false
UPDATE_NPM=false

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
	--update-npm)
		UPDATE_NPM=true
		shift
		;;
	--help | -h)
		echo "Usage: $0 [--stow] [--update] [--update-unstable] [--update-npm]"
		echo ""
		echo "Rebuild dotfiles using Nix + Stow (default) or Stow-only mode"
		echo ""
		echo "Options:"
		echo "  --stow             Use Stow-only mode (bypass Nix, dotfiles only)"
		echo "  --update           Update ALL flake inputs before rebuilding"
		echo "  --update-unstable  Update only unstable inputs (nixpkgs-unstable, nix-darwin, home-manager-unstable, dotfiles)"
		echo "  --update-npm       Only update npm tools (reads list from Nix config, skips rebuild)"
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

	# Run Stow to symlink dotfiles
	echo ""
	echo "🔗 Running Stow to symlink dotfiles..."
	(cd stow && ./install.sh)
}

# Function to use GNU Stow
use_stow() {
	echo ""
	echo "🔗 Using Stow-only mode (dotfiles only, no system changes)..."
	cd stow
	./install.sh
}

# Function to update npm tools only
update_npm_tools() {
	echo ""
	echo "📦 Updating npm tools only (using bun)..."

	# Query npm tools from Nix configuration
	if [[ "$OS" == "Darwin" ]]; then
		CONFIG_ATTR="darwinConfigurations"
	else
		CONFIG_ATTR="nixosConfigurations"
	fi

	echo "Reading npm tools from Nix config for $HOSTNAME..."
	NPM_TOOLS_JSON=$(nix eval ".#${CONFIG_ATTR}.${HOSTNAME}.config.home-manager.users.fredrik.npmTools" --json 2>/dev/null) || {
		echo "❌ Failed to read npmTools from Nix config"
		echo "Make sure hostname '$HOSTNAME' has a configuration in nix/hosts/"
		exit 1
	}

	# Parse JSON array to bash array
	readarray -t NPM_TOOLS < <(echo "$NPM_TOOLS_JSON" | jq -r '.[]')

	if [[ ${#NPM_TOOLS[@]} -eq 0 ]]; then
		echo "No npm tools configured"
		exit 0
	fi

	echo "Found ${#NPM_TOOLS[@]} npm tools to update"

	# Set up bun environment
	export BUN_INSTALL="$HOME/.bun"
	export PATH="$HOME/.bun/bin:$PATH"
	mkdir -p "$HOME/.bun/bin"

	# Get bun from flake's locked nixpkgs (reproducible)
	BUN_PATH=$(nix build --inputs-from . nixpkgs#bun --no-link --print-out-paths 2>/dev/null)/bin
	export PATH="$BUN_PATH:$PATH"

	echo ""
	for tool in "${NPM_TOOLS[@]}"; do
		echo "Processing $tool..."

		if bun install -g "$tool" 2>/dev/null; then
			echo "  ✓ $tool ready"
		else
			echo "  ⚠ Failed to install $tool"
		fi
	done

	echo ""
	echo "✅ npm tools update complete!"
}

# Main logic
if [[ "$UPDATE_NPM" == "true" ]]; then
	if ! command -v nix &>/dev/null; then
		echo "❌ Nix is required for --update-npm flag (to read config and get nodejs)"
		exit 1
	fi
	update_npm_tools
elif [[ "$STOW_FALLBACK" == "true" ]]; then
	use_stow
elif command -v nix &>/dev/null; then
	use_nix
else
	echo "⚠️  Nix not found, using Stow-only mode..."
	use_stow
fi

echo ""
echo "✅ Dotfiles rebuild complete!"
