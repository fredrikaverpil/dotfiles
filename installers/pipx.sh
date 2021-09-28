#/bin/bash -ex

# https://github.com/pypa/pipx

# Per-platform settings
case `uname` in
    Darwin)
        # commands for Linux go here
        if [ ! -d ~/.pyenv ]; then
            brew install openssl readline sqlite3 xz zlib

            curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
        fi
    ;;
    Linux)
        # commands for Linux go here
        echo "kaka"
        if ! command -v pipx &> /dev/null; then
            echo "jkaak"
            pyenv global 3.9.7
            PIP_REQUIRE_VIRTUALENV=false python -m pip install -U pipx
            pyenv global system

            sudo ln -s $HOME/.pyenv/versions/3.9.7/bin/pipx /usr/bin/pipx
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
