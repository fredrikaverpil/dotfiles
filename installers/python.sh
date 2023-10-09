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
	if [ ! -f ~/.local/bin/poetry ]; then $(brew --prefix)/bin/pipx install poetry; fi

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

		$HOME/.pyenv/bin/pyenv install $base_python_version
	fi

	# update pip
	PIP_REQUIRE_VIRTUALENV=false $HOME/.pyenv/bin/pyenv exec pip install -U pip

	# install pipx
	if [ ! -f /usr/bin/pipx ]; then
		PIP_REQUIRE_VIRTUALENV=false $HOME/.pyenv/bin/pyenv exec pip install -U pipx

		# clean up symlinks pointing to the wrong pipx
		if [ -f /usr/bin/pipx ]; then sudo rm /usr/bin/pipx; fi
		if [ -f ~/.local/bin/pipx ]; then rm ~/.local/bin/pipx; fi

		# set up symlink
		pipx_path=$($HOME/.pyenv/bin/pyenv prefix)/bin/pipx
		sudo ln -s $pipx_path /usr/bin/pipx
	fi

	# pipx-managed tools
	if [ ! -f ~/.local/bin/poetry ]; then /usr/bin/pipx install poetry; fi

	;;
*) ;;
esac
