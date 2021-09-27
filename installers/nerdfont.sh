#/bin/bash -ex


# https://www.nerdfonts.com


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here

    ;;
    Linux)
        # commands for Linux go here
        curl --location --output ~/downloads/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
        unzip -o ~/downloads/FiraCode.zip -d ~/.fonts
        rm ~/downloads/FiraCode.zip
        fc-cache -fv
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac