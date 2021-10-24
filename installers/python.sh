#/bin/bash -ex

# https://github.com/pyenv/pyenv/wiki
# https://github.com/pyenv/pyenv-installer
# https://github.com/pypa/pipx

# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here

        base_python_version=`cat .python-version`

        if [ ! -d ~/.pyenv ]; then
            brew install pyenv pyenv-virtualenv
        fi

        if command -v pyenv &> /dev/null; then
            if [ ! -d ~/.pyenv/versions/${base_python_version} ]; then
            brew install openssl readline sqlite3 xz zlib  # required to build python
            pyenv install $base_python_version
            fi
        fi

        if command -v pipx &> /dev/null; then
            brew install pipx
        fi

        # pipx-installations
        if [ ! -f ~/.local/bin/ipython ]; then pipx install ipython --pip-args rich ; fi
        if [ ! -f ~/.local/bin/black ]; then pipx install black ; fi
        if [ ! -f ~/.local/bin/poetry ]; then pipx install poetry ; fi
    ;;
    Linux)
        # commands for Linux go here

        base_python_version=`cat .python-version`
        pipx_target_path=$HOME/.pyenv/versions/$base_python_version/bin/pipx

        # install python via pyenv
        if [ ! -d ~/.pyenv ]; then
            if command -v apt-get &> /dev/null; then

            sudo apt-get install -y gcc

            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

            # install pyenv
            echo "Installing pyenv into ${HOME}/.pyenv ..."
            curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

            # install python version
            $HOME/.pyenv/bin/pyenv install $base_python_version
            fi
        fi

        # delete symlink and pipx if it is pointing to the wrong python installation
        if [ ! -f /usr/bin/pipx ] || [ "$(readlink /usr/bin/pipx)" != "$pipx_target_path" ]; then
            sudo rm -f /usr/bin/pipx
            rm -rf ~/.local/pipx
        fi

        # install pipx
        if [ ! -f /usr/bin/pipx ]; then
            PIP_REQUIRE_VIRTUALENV=false $HOME/.pyenv/versions/$base_python_version/bin/python -m pip install -U pipx
            sudo ln -s $pipx_target_path /usr/bin/pipx
        fi

        # pipx-installations
        if [ ! -f ~/.local/bin/ipython ]; then /usr/bin/pipx install ipython --pip-args rich ; fi
        if [ ! -f ~/.local/bin/black ]; then /usr/bin/pipx install black ; fi
        if [ ! -f ~/.local/bin/poetry ]; then /usr/bin/pipx install poetry ; fi

    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac
