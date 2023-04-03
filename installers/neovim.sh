#!/bin/bash -ex

if [ ! -d "$HOME/.config/NvChad" ]; then
    git clone https://github.com/NvChad/NvChad ~/.config/NvChad --depth 1
fi

if [ ! -d "$HOME/.config/LazyVim" ]; then
    git clone --recursive https://github.com/LazyVim/starter.git ~/.config/LazyVim
fi
