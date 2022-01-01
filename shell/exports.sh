# shellcheck shell=bash

# Global settings
export PIP_REQUIRE_VIRTUALENV=true                      # use --isolated to bypass
export PATH="$HOME/.local/bin:$PATH"                    # pipx-installed binaries
export PYENV_ROOT="$HOME/.pyenv"                        # pyenv
export PATH="$PYENV_ROOT/bin:$PATH"                     # pyenv
export PATH="$PATH:$HOME/code/repos/dotfiles/shell/bin" # dotfiles-bin
export PATH="$PATH:$HOME/.cargo/bin"                    # rust

#Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here
    export HOMEBREW_NO_ANALYTICS=1
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    export CLICOLOR=1 # Enable colors

    # nvm
    if [ "$(uname -m)" = "arm64" ]; then
        export NVM_DIR="$HOME/.nvm"
    elif [ "$(uname -m)" = "x86_64" ]; then
        export NVM_DIR="$HOME/.nvm_x86"
    fi
    ;;

Linux)
    # commands for Linux go here
    export NVM_DIR="$HOME/.nvm" # nvmexport NVM_DIR="$HOME/.nvm"                             # nvm
    ;;

MINGW64_NT-*)
    # commands for Git bash in Windows go here
    ;;
*) ;;
esac
