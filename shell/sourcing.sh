# shellcheck shell=bash
# shellcheck source=/dev/null

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
fi

# Linuxbrew
if [ -f ~/.linuxbrew/bin/brew ]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/fredrik/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Nix
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Pyenv + auto venv activation on cd
if [ -d ~/.pyenv ]; then
    eval "$(pyenv init --path)"
    # eval "$(pyenv virtualenv-init -)"
    cd . # trigger virtual_env_activate via cd hook

    function cd() {
        builtin cd "$@" || return
        virtual_env_activate
        node_version_manager
    }
fi

# NVM
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    . "/opt/homebrew/opt/nvm/nvm.sh"
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"
fi

# Rust
if [ -f ~/.cargo/env ]; then
    . "$HOME/.cargo/env"
fi

if [ -n "${ZSH_VERSION}" ]; then
    # assume Zsh

    # Zsh autocompletion
    if [ -d ~/.zsh/zsh-autosuggestions ]; then
        source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    fi

    if [ -d ~/.zsh/zsh-syntax-highlighting ]; then
        source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
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
fi
