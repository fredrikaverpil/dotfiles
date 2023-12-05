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

brew_prefix="$DOTFILES_BREW_PREFIX"
shell="$DOTFILES_SHELL"

# ----------------------------
# shell-agnostic configuration
# ----------------------------

if [ -f ~/.cargo/env ]; then
	source "$HOME/.cargo/env"
fi

if [ -n "$brew_prefix" ]; then
	# source "$brew_prefix/opt/nvm/nvm.sh"
	eval "$(atuin init $shell --disable-up-arrow)"
	eval "$(direnv hook $shell)"
	eval "$(zoxide init $shell)"
	eval "$(starship init $shell)"

	# GitHub Copilot X
	# Install with: npm i --global @githubnext/github-copilot-cli
	# Sets up aliases for `??`, `git?`, and `gh?`
	# More info: https://githubnext.com/projects/copilot-cli/
	if which github-copilot-cli >/dev/null; then
		eval "$(github-copilot-cli alias -- "$0")"
	fi

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

if [[ $shell == "zsh" ]]; then
	if [ -n "$brew_prefix" ]; then
		source <(pkgx --shellcode)
	elif [[ $shell == "bash" ]]; then
		eval "$(pkgx --shellcode)"
	fi
fi

function cd() {
	builtin cd "$@" || return
	virtual_env_activate
	# node_version_manager  # TODO: with pkgx, maybe nvm is no longer needed?
}
cd . # trigger cd overrides
