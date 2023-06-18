#!/bin/bash -e

# this will install so that nvim can be launched with NVIM_APPNAME, see aliases.sh
#
# see shell/bin/nvims how to start the different nvim distros

echo "About to remove default neovim dirs, continue? (y/n)"
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	rm -rf ~/.config/nvim
	rm -rf ~/.local/share/nvim
	rm -rf ~/.state/nvim
	rm -rf ~/.cache/nvim
fi

echo "About to install (git clone) neovim distros, continue? (y/n)"
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	if [ ! -d "$HOME/.config/LazyVim" ]; then
		git clone --recursive https://github.com/LazyVim/starter.git ~/.config/LazyVim
	fi

	if [ ! -d "$HOME/.config/NvChad" ]; then
		git clone https://github.com/NvChad/NvChad ~/.config/NvChad --depth 1
	fi

	if [ ! -d "$HOME/.config/AstroNvim" ]; then
		git clone https://github.com/AstroNvim/AstroNvim.git ~/.config/AstroNvim --depth 1
	fi

	if [ ! -d "$HOME/.config/kickstart" ]; then
		git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/kickstart | bash
	fi
fi
