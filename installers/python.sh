#/bin/bash -ex

# https://github.com/pyenv/pyenv/wiki
# https://github.com/pyenv/pyenv-installer
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
        if [ ! -d ~/.pyenv ]; then
            if command -v apt-get &> /dev/null; then
            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
            # install
            curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

            # install version
            $HOME/.pyenv/bin/pyenv install 3.9.7
            fi

            if ! command -v pipx &> /dev/null; then
                PIP_REQUIRE_VIRTUALENV=false $HOME/.pyenv/versions/3.9.7/bin/python -m pip install -U pipx
                sudo ln -s $HOME/.pyenv/versions/3.9.7/bin/pipx /usr/bin/pipx
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
