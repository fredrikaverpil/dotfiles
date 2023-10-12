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
	if [[ -z "$NVMRC_DOTFILES_PATH" ]]; then
		if [ -f .nvmrc ]; then
			nvm use
			export NVMRC_DOTFILES_PATH=$PWD/.nvmrc
		fi
	else
		parent_nvmdir="$(dirname "$NVMRC_DOTFILES_PATH")"
		if [[ "$PWD"/ != "$parent_nvmdir"/* ]]; then
			nvm deactivate
			export NVMRC_DOTFILES_PATH=""
		fi
	fi
}

# Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NVM
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
	. "/opt/homebrew/opt/nvm/nvm.sh"
elif [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ]; then
	. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
	. "$HOME/.nvm/nvm.sh"
fi

# Rust
if [ -f ~/.cargo/env ]; then
	. "$HOME/.cargo/env"
fi

# ----------------------------
# shell-specific configuration
# ----------------------------

if [ -n "${ZSH_VERSION}" ]; then
	# assume zsh

	# auto suggestions
	if [ -d ~/.zsh/zsh-autosuggestions ]; then
		source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
	fi

	# zsh syntax highlighting
	if [ -d ~/.zsh/zsh-syntax-highlighting ]; then
		source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
	fi

	# homebrew zsh site functions
	if [ -d /opt/homebrew/share/zsh/site-functions ]; then
		# https://docs.brew.sh/Shell-Completion
		export FPATH=/opt/homebrew/share/zsh/site-functions:$FPATH
		autoload -Uz compinit
		compinit
	fi

	# mcfly
	if [ -f /opt/homebrew/bin/mcfly ] || [ -f /usr/local/bin/mcfly ]; then
		eval "$(mcfly init zsh)"
	fi

	# Starship
	if command -v starship &>/dev/null; then
		eval "$(starship init zsh)"
	fi

	# OrbStack
	if [ -f ~/.orbstack/shell/init.zsh ]; then
		source ~/.orbstack/shell/init.zsh 2>/dev/null || :
	fi

	# zoxide
	eval "$(zoxide init zsh)"

	# google-cloud-sdk
	source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
	source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

elif [ -n "${BASH_VERSION}" ]; then
	# assume Bash

	# NVM bash completion
	if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
		# macOS, installed via homebrew
		. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
	elif [ -s "$HOME/.nvm/bash_completion" ]; then
		# linux, installed via official script
		. "$HOME/.nvm/bash_completion"
	fi

	# Bash autocompletion
	if [ -f /etc/profile.d/bash_completion.sh ]; then
		source /etc/profile.d/bash_completion.sh
	fi

	# mcfly
	if [ -f /opt/homebrew/bin/mcfly ] || [ -f /usr/local/bin/mcfly ]; then
		eval "$(mcfly init bash)"
	fi

	# Starship
	if command -v starship &>/dev/null; then
		eval "$(starship init bash)"
	fi

	# OrbStack
	if [ -f ~/.orbstack/shell/init.bash ]; then
		source ~/.orbstack/shell/init.bash 2>/dev/null || :
	fi

	# google-cloud-sdk
	source "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc"

fi

# ----------------------------------
# hooks and on-shell load evaluation
# ----------------------------------

# Evaluate on cd and on initial shell load
if [ -d ~/.pyenv ] && [ -d ~/.nvm ]; then

	eval "$(pyenv init --path)"
	# eval "$(pyenv virtualenv-init -)"

	function cd() {
		builtin cd "$@" || return
		virtual_env_activate
		node_version_manager
	}

	cd . # trigger virtual_env_activate via cd hook (for initial shell load)

fi
