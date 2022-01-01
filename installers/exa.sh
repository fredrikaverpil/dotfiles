#!/bin/bash -ex

# https://github.com/ogham/exa

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    brew install exa

    ;;
Linux)
    # commands for Linux go here

    # Use nix until exa is available on apt
    if ! command -v exa &>/dev/null; then
        nix-env -i exa
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