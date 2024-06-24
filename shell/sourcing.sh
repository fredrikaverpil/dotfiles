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

function zsh_completion() {

	if [ -n "$brew_prefix" ]; then
		export FPATH=$brew_prefix/share/zsh/site-functions:$FPATH

		source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
		source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	fi

	if [ -f "$brew_prefix/share/google-cloud-sdk" ]; then
		source "$brew_prefix/share/google-cloud-sdk/path.zsh.inc"
		source "$brew_prefix/share/google-cloud-sdk/completion.zsh.inc"
	fi

	export FPATH=$DOTFILES/work/zsh/site-functions:$FPATH

	# Makefile completion
	zstyle ':completion:*:*:make:*' tag-order 'targets'
	zstyle ':completion:*:make:*:targets' call-command true

	autoload -Uz compinit
	compinit
}

# ----------------------------
# globals
# ----------------------------

brew_prefix="$DOTFILES_BREW_PREFIX"
shell="$DOTFILES_SHELL"

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

# ----------------------------
# shell-agnostic configuration
# ----------------------------

if [ -f ~/.cargo/env ]; then
	source "$HOME/.cargo/env"
fi

if [ -n "$brew_prefix" ]; then
	# TODO: evaluate whether pkgx can replace nvm
	# source "$brew_prefix/opt/nvm/nvm.sh"

	eval "$(atuin init $shell --disable-up-arrow)"
	eval "$(direnv hook $shell)"
	eval "$(zoxide init $shell)"
	eval "$(starship init $shell)"

fi

# ----------------------------
# shell-specific configuration
# ----------------------------

if [[ $shell == "zsh" ]]; then

	zsh_completion

elif [[ $shell == "bash" ]]; then
	if [ -f "$brew_prefix/share/google-cloud-sdk" ]; then
		source "$brew_prefix/share/google-cloud-sdk/path.bash.inc"
		source "$brew_prefix/share/google-cloud-sdk/completion.bash.inc"
	fi

fi
