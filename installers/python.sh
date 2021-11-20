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

        if [ ! -d ~/.pyenv/plugins/pyenv-alias ]; then
            git clone https://github.com/s1341/pyenv-alias.git ~/.pyenv/plugins/pyenv-alias
        fi

        if command -v pyenv &> /dev/null; then
            if [ ! -d ~/.pyenv/versions/${base_python_version} ]; then
                brew install openssl readline sqlite3 xz zlib  # required to build python
                pyenv install $base_python_version
            fi
        fi

        brew86 install openssl readline sqlite3 xz zlib

        if command -v pipx &> /dev/null; then
            brew install pipx
        fi

        # pipx-installations
        if [ ! -f ~/.local/bin/ipython ]; then pipx install ipython --pip-args rich ; fi
        if [ ! -f ~/.local/bin/black ]; then pipx install black ; fi
        if [ ! -f ~/.local/bin/poetry ]; then pipx install poetry ; fi
        if [ ! -f ~/.local/bin/bandit ]; then pipx install bandit ; fi
        if [ ! -f ~/.local/bin/mypy ]; then pipx install mypy ; fi
        if [ ! -f ~/.local/bin/flake8 ]; then pipx install flake8 ; fi
        if [ ! -f ~/.local/bin/flake8 ]; then pipx install pre-commit ; fi

        # x86
        if command -v pyenv86 &> /dev/null; then
            if [ ! -d ~/.pyenv/versions/${base_python_version}_x86 ]; then
                # http://sixty-north.com/blog/pyenv-apple-silicon.html

                softwareupdate —install-rosetta
                arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

                brew86 install openssl readline sqlite3 xz zlib  # required to build python

                CFLAGS="-I$(brew86 --prefix openssl)/include" \
                LDFLAGS="-L$(brew86 --prefix openssl)/lib" \
                VERSION_ALIAS="${base_python_version}_x86" \
                pyenv86 install -v $base_python_version

                brew86 install pipx
                pipx86 install poetry --suffix @x86

            fi
        fi
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
        if [ ! -f ~/.local/bin/bandit ]; then /usr/bin/pipx install bandit ; fi
        if [ ! -f ~/.local/bin/mypy ]; then /usr/bin/pipx install mypy ; fi
        if [ ! -f ~/.local/bin/flake8 ]; then /usr/bin/pipx install flake8 ; fi
        if [ ! -f ~/.local/bin/flake8 ]; then /usr/bin/pipx install pre-commit ; fi

    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac
