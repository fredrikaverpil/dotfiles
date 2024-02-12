#!/bin/bash -e

curl -L -o ~/Downloads/nvim-macos.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz
rm -rf ~/nvim-nightly
tar -xvf ~/Downloads/nvim-macos.tar.gz -C ~/
mv ~/nvim-macos ~/nvim-nightly
