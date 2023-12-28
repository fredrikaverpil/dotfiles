# shellcheck shell=bash

# ----------------------------
# functions and shell-agnostic
# ----------------------------

function add_to_path() {
	# NOTE: zsh only
	# usage:
	# add_to_path prepend /path/to/prepend
	# add_to_path append /path/to/append
	if [ -d "$2" ]; then

		if [[ ! ":$PATH:" =~ .*":$2:.*" ]]; then
			# echo "Warning: $2 is already in \$PATH"
			remove_from_path "$2"
		fi

		if [ "$1" = "prepend" ]; then
			PATH="$2:$PATH"
			export PATH
		elif [ "$1" = "append" ]; then
			PATH="$PATH:$2"
			export PATH
		else
			echo "Unknown option. Use 'prepend' or 'append'."
		fi
	fi
}

function remove_from_path() {
	# NOTE: zsh only
	# usage:
	# remove_from_path /path/to/remove
	if [ -d "$1" ] && [[ ":$PATH:" =~ .*":$1:.*" ]]; then
		PATH="${PATH//$1:/}"
		export PATH
	fi
}

# ----------------------------
# globals
# ----------------------------

if [ -n "${ZSH_VERSION}" ]; then
	shell="zsh"
	export DOTFILES_DEBUG_SHELL_ZSH="true"
elif [ -n "${BASH_VERSION}" ]; then
	shell="bash"
	export DOTFILES_DEBUG_SHELL_BASH="true"
else
	shell=""
fi

# ----------------------------
# exports
# ----------------------------

# NOTE: brew shellenv exports several environment variables and extends $PATH
if [ -f /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
	brew_prefix="$(brew --prefix)"
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	brew_prefix="$(brew --prefix)"
else
	echo "Please install Homebrew and the Brewfile."
	brew_prefix=""
fi

export DOTFILES="$HOME/code/dotfiles"
export DOTFILES_SHELL=$shell
export DOTFILES_BREW_PREFIX=$brew_prefix
export HOMEBREW_NO_ANALYTICS=1
echo "Warning: Enabling Task's remote taskfiles feature"
export TASK_X_REMOTE_TASKFILES=1   # TODO: remove this once go-task/Task graduates this expirment
export PIP_REQUIRE_VIRTUALENV=true # use pip --isolated to bypass
export PYENV_ROOT="$HOME/.pyenv"   # pyenv

add_to_path append "$HOME/.docker/bin"
add_to_path append "$HOME/.cargo/bin"
add_to_path append "$HOME/go/bin"

# NOTE: the last prepend appears first in $PATH, so make sure the order is correct below
add_to_path prepend "$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin"
add_to_path prepend "$PYENV_ROOT/bin"  # pyenv
add_to_path prepend "$HOME/.local/bin" # user-installed binaries
add_to_path prepend "$DOTFILES/shell/bin"

# load .env file if it exists
# shellcheck disable=SC1090
if [ -f "$HOME/.shell/.env" ]; then
	set -a
	source $HOME/.shell/.env
	set +a
else
	echo "Warning: $HOME/.shell/.env does not exist"
fi

# Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here

	add_to_path append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

	# # nvm
	# if [ "$(uname -m)" = "arm64" ]; then
	# 	export NVM_DIR="$HOME/.nvm"
	# elif [ "$(uname -m)" = "x86_64" ]; then
	# 	export NVM_DIR="$HOME/.nvm_x86"
	# fi

	;;

Linux)
	# commands for Linux go here

	# export NVM_DIR="$HOME/.nvm"

	;;

*) ;;
esac
