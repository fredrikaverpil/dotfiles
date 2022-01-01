#!/bin/bash -ex

# https://starship.rs

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    brew install starship

    ;;
Linux)
    # commands for Linux go here
    if [ ! -f /usr/local/bin/starship ]; then
        sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
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
