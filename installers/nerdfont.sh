#/bin/bash -ex

# https://www.nerdfonts.com


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here

    ;;
    Linux)
        # commands for Linux go here
        if ! compgen -G "${HOME}/.fonts/Fira*" > /dev/null; then
            if command -v fc-cache &> /dev/null; then
                # Ubuntu
                curl --location --output ~/downloads/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
                unzip -o ~/downloads/FiraCode.zip -d ~/.fonts
                rm ~/downloads/FiraCode.zip
                fc-cache -fv
            fi
        fi
    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac