#!/bin/bash -ex

# https://www.nerdfonts.com

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	if ! ls "/Users/${USER}/Library/Fonts/JetBrainsMono"* 1>/dev/null 2>&1; then
		curl --location --output ~/Downloads/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
		unzip -o ~/Downloads/JetBrainsMono.zip -d ~/Downloads/JetBrainsMono
		mkdir -p ~/Library/Fonts/
		cp -v ~/Downloads/JetBrainsMono/* ~/Library/Fonts/
		rm ~/Downloads/JetBrainsMono.zip
		rm -r ~/Downloads/JetBrainsMono
	fi
	;;
Linux)
	# commands for Linux go here
	if ! ls ~/.local/share/fonts/JetBrainsMono* 1>/dev/null 2>&1; then
		# Ubuntu
		curl --location --output ~/Downloads/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
		unzip -o ~/Downloads/JetBrainsMono.zip -d ~/Downloads/JetBrainsMono
		mkdir -p ~/.local/share/fonts
		sudo cp -v ~/Downloads/JetBrainsMono/* ~/.local/share/fonts
		rm ~/Downloads/JetBrainsMono.zip
		rm -r ~/Downloads/JetBrainsMono

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
