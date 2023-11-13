# shellcheck shell=bash
# shellcheck source=/dev/null

# ----------------------------
# functions and shell-agnostic
# ----------------------------

function virtual_env_activate() {
	if [[ -z "$VIRTUAL_ENV" ]]; then
		# if .venv folder is found then activate the vitualenv
		if [ -d ./.venv ] && [ -f ./.venv/bin/activate ]; then
			source ./.venv/bin/activate
		fi
	else
		# check the current folder belong to earlier VIRTUAL_ENV folder
		parentdir="$(dirname "$VIRTUAL_ENV")"
		if [[ "$PWD"/ != "$parentdir"/* ]]; then
			deactivate
		fi
	fi
}

function node_version_manager() {
	if [[ -z "$NVMRC_PATH" ]]; then
		if [ -f .nvmrc ]; then
			nvm use
			export NVMRC_PATH=$PWD/.nvmrc
		fi
	else
		parent_nvmdir="$(dirname "$NVMRC_PATH")"
		if [[ "$PWD"/ != "$parent_nvmdir"/* ]]; then
			nvm deactivate
			export NVMRC_PATH=""
		fi
	fi
}

# ----------------------------
# globals
# ----------------------------

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

if [ -n "${ZSH_VERSION}" ]; then
	shell="zsh"
elif [ -n "${BASH_VERSION}" ]; then
	shell="bash"
else
	shell=""
fi

# ----------------------------
# shell-agnostic configuration
# ----------------------------

if [ -f ~/.cargo/env ]; then
	source "$HOME/.cargo/env"
fi

if [ -n "$brew_prefix" ]; then
	source "$brew_prefix/opt/nvm/nvm.sh"
	eval "$(mcfly init $shell)"
	eval "$(starship init $shell)"
	eval "$(zoxide init $shell)"
fi

# ----------------------------
# shell-specific configuration
# ----------------------------

if [[ $shell == "zsh" ]]; then
	if [ -n "$brew_prefix" ]; then
		export FPATH=$brew_prefix/share/zsh/site-functions:$FPATH
		autoload -Uz compinit
		compinit

		source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
		source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	fi

	if [ -f "$brew_prefix/share/google-cloud-sdk" ]; then
		source "$brew_prefix/share/google-cloud-sdk/path.zsh.inc"
		source "$brew_prefix/share/google-cloud-sdk/completion.zsh.inc"
	fi

elif [[ $shell == "bash" ]]; then
	if [ -f "$brew_prefix/share/google-cloud-sdk" ]; then
		source "$brew_prefix/share/google-cloud-sdk/path.bash.inc"
		source "$brew_prefix/share/google-cloud-sdk/completion.bash.inc"
	fi
fi

# ----------------------------------
# hooks and on-shell load evaluation
# ----------------------------------

# Evaluate on cd and on initial shell load
if [ -d ~/.pyenv ] && [ -d ~/.nvm ]; then

	# TODO: refactor this;
	# - Always override cd function
	# - Initialize pyenv like nvm is initialized further up in this script
	# - Check for ~/.pyenv in virtual_env_activate function
	# - Check for ~/.nvm in node_version_manager function

	eval "$(pyenv init --path)"
	# eval "$(pyenv virtualenv-init -)"

	function cd() {
		builtin cd "$@" || return
		virtual_env_activate
		node_version_manager
	}

	cd . # trigger pyenv/nvm inits

fi
