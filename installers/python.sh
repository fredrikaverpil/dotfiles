#!/bin/bash -ex

# https://github.com/pyenv/pyenv/wiki
# https://github.com/pyenv/pyenv-installer
# https://github.com/pypa/pipx

base_python_version=$(cat .python-version)

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here

    # install pyenv
    if [ ! -d ~/.pyenv ]; then
        curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
    fi

    # install python
    if [ ! -d $HOME/.pyenv/versions/${base_python_version} ]; then
        brew install openssl readline sqlite3 xz zlib # required to build python
        ~/.pyenv/bin/pyenv install $base_python_version
    fi

    # install pipx
    if [ ! -d $(brew --prefix)/bin/pipx ]; then
        brew install pipx
    fi

    # install pipx-managed tools
    if [ ! -f ~/.local/bin/ipython ]; then $(brew --prefix)/bin/pipx install ipython --pip-args rich; fi
    if [ ! -f ~/.local/bin/bpython ]; then $(brew --prefix)/bin/pipx install bpython; fi
    if [ ! -f ~/.local/bin/black ]; then $(brew --prefix)/bin/pipx install black; fi
    if [ ! -f ~/.local/bin/flake8 ]; then $(brew --prefix)/bin/pipx install flake8; fi
    if [ ! -f ~/.local/bin/bandit ]; then $(brew --prefix)/bin/pipx install bandit; fi
    if [ ! -f ~/.local/bin/poetry ]; then $(brew --prefix)/bin/pipx install poetry; fi
    if [ ! -f ~/.local/bin/pre-commit ]; then $(brew --prefix)/bin/pipx install pre-commit; fi
    if [ ! -f ~/.local/bin/rich-cli ]; then $(brew --prefix)/bin/pipx install rich-cli; fi

    # install python, pipx and pipx-managed tools for x86_64
    if [ "$(uname -m)" == "arm64" ] && [ ! -d ~/.pyenv/versions/${base_python_version}_x86 ]; then
        # http://sixty-north.com/blog/pyenv-apple-silicon.html

        git clone https://github.com/s1341/pyenv-alias.git ~/.pyenv/plugins/pyenv-alias
        brew86 install openssl readline sqlite3 xz zlib # required to build python
        VERSION_ALIAS="${base_python_version}_x86" \
            pyenv86 install -v $base_python_version

        brew86 install pipx

        if [ ! -f ~/.local/bin/poetry@x86 ]; then pipx86 install poetry --suffix @x86; fi
    fi

    ;;
Linux)
    # commands for Linux go here

    pipx_target_path=$HOME/.pyenv/versions/$base_python_version/bin/pipx

    # install pyenv
    if [ ! -d ~/.pyenv ]; then
        curl -s -S -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
    fi

    # install python
    if [ ! -d $HOME/.pyenv/versions/${base_python_version} ]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y gcc

            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        fi

        ~/.pyenv/bin/pyenv install $base_python_version
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
    if [ ! -f ~/.local/bin/ipython ]; then /usr/bin/pipx install ipython --pip-args rich; fi
    if [ ! -f ~/.local/bin/bpython ]; then /usr/bin/pipx install bpython; fi
    if [ ! -f ~/.local/bin/black ]; then /usr/bin/pipx install black; fi
    if [ ! -f ~/.local/bin/poetry ]; then /usr/bin/pipx install poetry; fi
    if [ ! -f ~/.local/bin/pre-commit ]; then /usr/bin/pipx install pre-commit; fi
    if [ ! -f ~/.local/bin/rich-cli ]; then /usr/bin/pipx install rich-cli; fi

    ;;
*) ;;
esac
