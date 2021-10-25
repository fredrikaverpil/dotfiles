#/bin/bash -ex

# https://docs.brew.sh/Homebrew-on-Linux

# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    ;;
    Linux)
        # commands for Linux go here

        # if [ ! -d ~/.linuxbrew ]; then
        #     git clone https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew
        #     mkdir ~/.linuxbrew/bin
        #     ln -s ~/.linuxbrew/Homebrew/bin/brew ~/.linuxbrew/bin
        #     eval "$(~/.linuxbrew/bin/brew shellenv)"
        #     ~/.linuxbrew/bin/brew tap homebrew/core
        #     ~/.linuxbrew/bin/brew doctor
        # fi

    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac