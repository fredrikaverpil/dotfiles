#!/bin/bash -e

curl -L -o ~/Downloads/nvim-macos.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz
rm -rf ~/nvim-nightly
tar -xvf ~/Downloads/nvim-macos.tar.gz -C ~/
mv ~/nvim-macos-arm64 ~/nvim-nightly
