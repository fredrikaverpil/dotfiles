#/bin/bash -ex

# https://github.com/nvm-sh/nvm


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        brew install nvm

        # nvm install 12

        # pyenv global 3.9.9
        # nvm install 14
        # pyenv global system
    ;;
    Linux)
        # commands for Linux go here
        if ! command -v nvm &> /dev/null; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
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