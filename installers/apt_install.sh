#!/bin/bash

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	;;
Linux)
	# commands for Linux go here

	# for running nvim.appimage
	apt install fuse

	# for building neovim plugins
	apt install make cmake gcc g++ clang

	apt install bat
	apt install ripgrep
	apt install fd-find
	apt install fzf
	apt install asciinema
	;;
FreeBSD)
	# commands for FreeBSD go here
	;;
MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac
