#!/bin/bash -e

# usage:
# $ ./neovim.sh
# or, for nightly build:
# ./neovim.sh --nightly

MANUAL_NVIM_BINARY="$HOME/.nvim/bin/nvim"
DOWNLOAD_FILENAME="nvim-macos-arm64.tar.gz"

# Check if --nightly parameter was provided
if [[ "$1" == "--nightly" ]]; then
	echo "Preparing to install Neovim nightly build..."
	DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz"
else
	echo "Preparing to install latest stable Neovim release..."
	# Get the latest release tag using the GitHub API
	LATEST_TAG=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
	if [[ -z "$LATEST_TAG" ]]; then
		echo "Error: Could not determine latest Neovim version. Check your internet connection."
		exit 1
	fi
	echo "Latest version: $LATEST_TAG"
	DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/$LATEST_TAG/nvim-macos-arm64.tar.gz"
fi

# Create Downloads directory if it doesn't exist
mkdir -p ~/Downloads

# Download tar.gz into ~/Downloads/ (retain filename and overwrite if necessary)
echo "Downloading Neovim build from $DOWNLOAD_URL..."
cd ~/Downloads
curl -LOs "$DOWNLOAD_URL" || {
	echo "Error: Download failed."
	exit 1
}

# Remove extended attributes to avoid "unknown developer" warning
echo "Removing extended attributes..."
xattr -c "./$DOWNLOAD_FILENAME" || echo "Warning: Could not remove extended attributes."

# Extract into ~/.nvim
echo "Extracting Neovim..."
rm -rf ~/.nvim
mkdir -p ~/.nvim
tar xzvf "$DOWNLOAD_FILENAME" -C ~/.nvim --strip-components=1 >/dev/null 2>&1 || {
	echo "Error: Extraction failed."
	exit 1
}

echo "Neovim installation completed: $MANUAL_NVIM_BINARY"
echo "You can now run Neovim using: $MANUAL_NVIM_BINARY"
