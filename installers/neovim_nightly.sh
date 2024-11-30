#!/bin/bash -e

MANUAL_NVIM_BINARY="$HOME/.nvim/bin/nvim"

# Install via brew
# brew unlink neovim
# brew install nvim --HEAD

# Download tar.gz into ~/Downloads/ (retain filename and overwrite if necessary)
echo "Downloading Neovim nightly build..."
cd ~/Downloads
curl -LOs https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz

# Remove extended attributes to avoid "unknown developer" warning
echo "Removing extended attributes..."
xattr -c ./nvim-macos-arm64.tar.gz

# Extract into ~/.nvim
echo "Extracting Neovim..."
rm -rf ~/.nvim
mkdir -p ~/.nvim
tar xzvf nvim-macos-arm64.tar.gz -C ~/.nvim --strip-components=1 >/dev/null 2>&1

echo "Neovim installation completed: $MANUAL_NVIM_BINARY"
