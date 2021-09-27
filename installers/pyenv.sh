#/bin/bash -ex

# https://github.com/pyenv/pyenv/wiki
# https://github.com/pyenv/pyenv-installer

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
            sudo apt-get install make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm-13 \
                libncursesw5-dev xz-utils tk8.6-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

            curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
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
