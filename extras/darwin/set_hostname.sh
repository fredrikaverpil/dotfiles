#!/bin/bash -ex

# take hostname as argument
# if no argument, raise error
if [ -z "$1" ]; then
	echo "Usage: $0 <hostname>"
	exit 1
fi

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	sudo scutil --set HostName "$1"
	sudo scutil --set LocalHostName "$1"
	sudo scutil --set ComputerName "$1"
	;;
Linux)
	# commands for Linux go here
	;;
FreeBSD)
	# commands for FreeBSD go here
	;;
MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac
