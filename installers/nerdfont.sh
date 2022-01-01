#!/bin/bash -ex

# https://www.nerdfonts.com

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    if ! ls /Users/${USER}/Library/Fonts/Fira* 1>/dev/null 2>&1; then
        curl --location --output $HOME/Downloads/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
        unzip -o $HOME/Downloads/FiraCode.zip -d $HOME/Downloads/FiraCode
        find $HOME/Downloads/FiraCode/ -name "*.otf" | xargs -0 cp -v "{}" $HOME/Library/Fonts/
        # cp $HOME/Downloads/FiraCode/*.otf $HOME/Library/Fonts/
        rm $HOME/Downloads/FiraCode.zip
        rm -r $HOME/Downloads/FiraCode
    fi
    ;;
Linux)
    # commands for Linux go here
    if ! ls $HOME/.local/share/fonts/Fira* 1>/dev/null 2>&1; then
        # Ubuntu
        curl --location --output $HOME/Downloads/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
        unzip -o $HOME/Downloads/FiraCode.zip -d $HOME/Downloads/FiraCode
        mkdir -p $HOME/.local/share/fonts
        sudo cp -v $HOME/Downloads/FiraCode/*.otf $HOME/.local/share/fonts
        rm $HOME/Downloads/FiraCode.zip
        rm -r $HOME/Downloads/FiraCode

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
