#!/bin/bash -e

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	;;
Linux)
	# commands for Linux go here

	# for running nvim.appimage
	sudo apt install fuse

	# for building neovim plugins
	sudo apt install make cmake gcc g++ clang
	;;
FreeBSD)
	# commands for FreeBSD go here
	;;
MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac

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

echo "For git clone to succeed, you must remove pre-existing distros."
echo "This is required for first-time install, as dotfiles installer have created the dirs."
echo "If doing this, you must re-run the dotfiles installer script after running this script."
echo "Do you want to remove the distro dirs in ~/.config? (y/n)"
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	rm -rf ~/.config/LazyVim
	rm -rf ~/.config/NvChad
	rm -rf ~/.config/AstroNvim
	rm -rf ~/.config/kickstart
	rm -rf ~/.config/NormalVim

	echo "NOTE: after installation, you must re-run the dotfiles installer."
fi

echo "About to install (git clone) neovim distros, continue? (y/n)"
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	if [ ! -d "$HOME/.config/LazyVim" ]; then
		git clone --recursive https://github.com/LazyVim/starter.git ~/.config/LazyVim
	else
		echo "LazyVim already exists, skipping"
	fi

	if [ ! -d "$HOME/.config/NvChad" ]; then
		git clone https://github.com/NvChad/NvChad ~/.config/NvChad --depth 1
	else
		echo "NvChad already exists, skipping"
	fi

	if [ ! -d "$HOME/.config/AstroNvim" ]; then
		git clone https://github.com/AstroNvim/AstroNvim.git ~/.config/AstroNvim --depth 1
	else
		echo "AstroNvim already exists, skipping"
	fi

	if [ ! -d "$HOME/.config/kickstart" ]; then
		git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/kickstart
	else
		echo "kickstart already exists, skipping"
	fi

	if [ ! -d "$HOME/.config/NormalVim" ]; then
		git clone https://github.com/NormalNvim/NormalNvim.git ~/.config/NormalVim --depth 1
	else
		echo "NormalVim already exists, skipping"
	fi
fi

echo "Neovim uses rust/cargo for some plugins. On first-time install, you must run rustup-init."
echo "Do you wish to run rustup-init, making cargo available? (y/n)"
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	rustup-init
fi
