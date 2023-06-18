#!/bin/bash -ex

# https://docs.brew.sh/Homebrew-on-Linux

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    echo "Install via Brewfile on macOS."
    ;;
Linux)
    # commands for Linux go here
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    ;;
FreeBSD)
    # commands for FreeBSD go here
    ;;
MINGW64_NT-*)
    # commands for Git bash in Windows go here
    ;;
*) ;;
esac
