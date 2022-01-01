#!/bin/bash -ex

apt_install() {
    if ! command -v "$1" &>/dev/null; then
        sudo apt-get install -y "$1"
    fi
}

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    echo "ZSH already installed by default on macOS"
    ;;
Linux)
    # commands for Linux go here
    if command -v zsh &>/dev/null; then
        apt_install zsh
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

# https://github.com/zsh-users/zsh-autosuggestions
if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
fi

# https://github.com/zsh-users/zsh-syntax-highlighting
if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
fi
