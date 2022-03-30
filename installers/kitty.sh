#!/bin/bash -ex

# https://github.com/kovidgoyal/kitty

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    brew install kitty

    if [ ! -d ~/.config/kitty/kitty-themes ]; then
        git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
    fi

    ;;
*) ;;
esac
