# shellcheck shell=bash

# Global settings
export PIP_REQUIRE_VIRTUALENV=true                      # use --isolated to bypass
export PATH="$HOME/.local/bin:$PATH"                    # pipx-installed binaries
export PYENV_ROOT="$HOME/.pyenv"                        # pyenv
export PATH="$PYENV_ROOT/bin:$PATH"                     # pyenv
export PATH="$PATH:$HOME/code/repos/dotfiles/shell/bin" # dotfiles-bin
export PATH="$PATH:$HOME/.cargo/bin"                    # rust

# Load .env file if it exists
# shellcheck disable=SC1090
if [ -f $HOME/.shell/.env ]; then
	set -a
	source $HOME/.shell/.env
	set +a
else
	echo "Warning: $HOME/.shell/.env does not exist"
fi

#Per-platform settings
case $(uname) in
Darwin)
	# commands for macOS go here
	export HOMEBREW_NO_ANALYTICS=1
	export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
	export CLICOLOR=1 # Enable colors

	# t-smart-tmux-session-manager
	export PATH=$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH

	# nvm
	if [ "$(uname -m)" = "arm64" ]; then
		export NVM_DIR="$HOME/.nvm"
	elif [ "$(uname -m)" = "x86_64" ]; then
		export NVM_DIR="$HOME/.nvm_x86"
	fi

	# go
	if [ "$(uname -m)" = "arm64" ]; then
		# export GOPATH=$HOME/go
		# export GOBIN=$GOPATH/bin
		export PATH=$PATH:$HOME/go/bin

		# NOTE: only set GOROOT to use non-default version of go
		# export GOROOT=/opt/homebrew/Cellar/go
		# export PATH=$PATH:$GOROOT/bin
	fi

	# ruby
	export PATH=/opt/homebrew/opt/ruby/bin:$PATH

	;;

Linux)
	# commands for Linux go here
	export NVM_DIR="$HOME/.nvm"
	export HOMEBREW_NO_ANALYTICS=1

	# t-smart-tmux-session-manager
	export PATH=$HOME/.tmux/plugins/t-smart-tmux-session-manager/bin:$PATH
	;;

MINGW64_NT-*)
	# commands for Git bash in Windows go here
	;;
*) ;;
esac
