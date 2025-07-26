#!/usr/bin/env bash
set -e

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Parse command line arguments
FORCE_MODE=false
STOW_FALLBACK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_MODE=true
            shift
            ;;
        --stow)
            STOW_FALLBACK=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--force] [--stow]"
            echo ""
            echo "Bootstrap dotfiles using Nix (preferred) or GNU Stow (fallback)"
            echo ""
            echo "Options:"
            echo "  --force    Force rebuild/overwrite existing symlinks"
            echo "  --stow     Use GNU Stow instead of Nix (fallback mode)"
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

echo "🚀 Bootstrapping dotfiles..."
echo "Platform: $OS"
echo "Hostname: $HOSTNAME"

# Function to use Nix
use_nix() {
    echo ""
    echo "📦 Using Nix for dotfiles management..."
    
    # Check if this hostname has a configuration
    if [[ ! -f "nix/hosts/$HOSTNAME/configuration.nix" ]]; then
        echo "❌ No Nix configuration found for hostname '$HOSTNAME'"
        echo "Available configurations:"
        find nix/hosts/ -maxdepth 1 -type d -not -path "nix/hosts/" | sed 's|nix/hosts/||' | sed 's/^/  - /' | sort
        echo ""
        echo "💡 Either:"
        echo "   1. Create nix/hosts/$HOSTNAME/configuration.nix"
        echo "   2. Use --stow for GNU Stow fallback"
        exit 1
    fi
    
    if [[ "$OS" == "Darwin" ]]; then
        echo "🍎 Found Darwin configuration for $HOSTNAME"
        if [[ "$FORCE_MODE" == "true" ]]; then
            echo "⚠️  Force mode: rebuilding Darwin configuration..."
            nix run nix-darwin -- switch --flake ".#$HOSTNAME" --impure
        else
            darwin-rebuild switch --flake ".#$HOSTNAME"
        fi
    elif [[ "$OS" == "Linux" ]]; then
        echo "🐧 Found NixOS configuration for $HOSTNAME"
        if [[ "$FORCE_MODE" == "true" ]]; then
            nixos-rebuild switch --flake ".#$HOSTNAME" --use-remote-sudo
        else
            nixos-rebuild switch --flake ".#$HOSTNAME"
        fi
    else
        echo "❌ Unsupported platform for Nix: $OS"
        echo "💡 Use --stow for GNU Stow fallback"
        exit 1
    fi
}

# Function to use GNU Stow
use_stow() {
    echo ""
    echo "🔗 Using GNU Stow for dotfiles management..."
    
    STOW_ARGS=""
    if [[ "$FORCE_MODE" == "true" ]]; then
        STOW_ARGS="--force"
    fi
    
    cd stow
    ./symlink.sh $STOW_ARGS
}

# Main logic
if [[ "$STOW_FALLBACK" == "true" ]]; then
    use_stow
elif command -v nix &>/dev/null; then
    use_nix
else
    echo "⚠️  Nix not found, falling back to GNU Stow..."
    use_stow
fi

echo ""
echo "✅ Dotfiles bootstrap complete!"