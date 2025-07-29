#!/usr/bin/env bash
set -e

# --- Configuration ---
INSTALL_DIR="$HOME/.nvim"
MANUAL_NVIM_BINARY="$INSTALL_DIR/bin/nvim"
DOWNLOAD_DIR="$HOME/Downloads"

# --- Platform Detection ---
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64) ASSET_KEY="linux-x86_64" ;;
            aarch64) ASSET_KEY="linux-arm64" ;;
            *) echo "Error: Unsupported Linux architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    Darwin)
        case "$ARCH" in
            x86_64) ASSET_KEY="macos-x86_64" ;;
            arm64) ASSET_KEY="macos-arm64" ;;
            *) echo "Error: Unsupported macOS architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    *)
        echo "Error: Unsupported operating system: $OS"
        exit 1
        ;;
esac

DOWNLOAD_FILENAME="nvim-${ASSET_KEY}.tar.gz"

# --- Version Selection ---
if [[ "$1" == "--nightly" ]]; then
    echo "Preparing to install Neovim nightly build..."
    RELEASE_TAG="nightly"
else
    echo "Preparing to install latest stable Neovim release..."
    LATEST_TAG=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    if [[ -z "$LATEST_TAG" ]]; then
        echo "Error: Could not determine latest Neovim version. Check your internet connection."
        exit 1
    fi
    echo "Latest version: $LATEST_TAG"
    RELEASE_TAG="$LATEST_TAG"
fi

DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/$RELEASE_TAG/$DOWNLOAD_FILENAME"

# --- Installation ---
echo "Target platform: $ASSET_KEY"
echo "Download URL: $DOWNLOAD_URL"

# Create Downloads directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# Download tar.gz
echo "Downloading Neovim build..."
curl -LOs "$DOWNLOAD_URL" || {
    echo "Error: Download failed."
    exit 1
}

# On macOS, remove extended attributes to avoid "unknown developer" warning
if [[ "$OS" == "Darwin" ]]; then
    echo "Removing extended attributes on macOS..."
    xattr -c "./$DOWNLOAD_FILENAME" || echo "Warning: Could not remove extended attributes."
fi

# Extract into target directory
echo "Extracting Neovim to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar xzvf "$DOWNLOAD_FILENAME" -C "$INSTALL_DIR" --strip-components=1 >/dev/null 2>&1 || {
    echo "Error: Extraction failed."
    exit 1
}

# --- Completion ---
echo "Neovim installation completed: $MANUAL_NVIM_BINARY"
echo "You can now run Neovim using: $MANUAL_NVIM_BINARY"
