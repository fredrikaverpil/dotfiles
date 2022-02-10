#!/bin/bash -ex

# https://github.com/sharkdp/bat

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    brew install bat

    ;;
Linux)
    # commands for Linux go here
    if ! command -v bat &>/dev/null; then
        sudo apt install bat
    fi

    ;;
*) ;;
esac
