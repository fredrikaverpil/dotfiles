#!/bin/sh

set -e

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Parse command line arguments
UPDATE_FLAKE=false
if [ "$1" = "--update" ]; then
	UPDATE_FLAKE=true
	echo "Will update flake inputs before rebuilding..."
fi

# Update flake inputs if requested
if [ "$UPDATE_FLAKE" = true ]; then
	echo "Updating flake inputs..."
	nix flake update
	echo "Flake inputs updated!"
fi

# Determine hostname
HOSTNAME=$(hostname -s)

# Apply the configuration based on system type
if [ "$HOSTNAME" = "zap" ] || [ "$HOSTNAME" = "plumbus" ]; then
	echo "Applying Darwin configuration for $HOSTNAME..."

	if command_exists darwin-rebuild; then
		darwin-rebuild switch --flake ~/.dotfiles#$HOSTNAME
	else
		echo "nix-darwin not found. Use ./nix/scripts/install-darwin.sh for initial setup."
		exit 1
	fi

elif [ "$HOSTNAME" = "rpi5-homelab" ]; then
	echo "Applying NixOS configuration for $HOSTNAME..."
	sudo nixos-rebuild switch --flake ~/.dotfiles#$HOSTNAME

else
	echo "Unknown hostname: $HOSTNAME"
	exit 1
fi

echo "Configuration applied successfully!"
