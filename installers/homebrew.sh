#!/bin/bash -ex

# https://docs.brew.sh/Homebrew-on-Linux

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here

	if ! command -v brew &>/dev/null; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	# x86 (disabled for now)
	# if [ ! -f /usr/local/bin/brew ] && [ "$(uname -m)" == "arm64" ]; then
	# 	echo "brew86"
	# 	softwareupdate —install-rosetta
	# 	arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	# fi
	;;
Linux)
	# commands for Linux go here
	#
	if ! command -v brew &>/dev/null; then
		sudo apt-get install build-essential procps curl file git
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
