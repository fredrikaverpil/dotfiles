#!/bin/bash -ex

# https://github.com/ogham/exa

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	echo "Install via Brewfile on macOS."

	;;
Linux)
	# commands for Linux go here

	# Use nix until exa is available on apt
	if ! command -v eza &>/dev/null; then
		nix-env -i eza
	fi

	;;
FreeBSD)
	# commands for FreeBSD go here
	;;
MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac
