# shellcheck shell=bash
# shellcheck source=/dev/null

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bash_profile.pre.bash" ]] && builtin source "$HOME/.fig/shell/bash_profile.pre.bash"

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
    eval "$(pyenv virtualenv-init -)"

    function cd() {
        builtin cd "$@" || return

        if [[ -z "$VIRTUAL_ENV" ]]; then
            ## If env folder is found then activate the vitualenv
            if [ -d ./.venv ] && [ -f ./venv/bin/activate ]; then
                source ./.venv/bin/activate
            fi
        else
            ## check the current folder belong to earlier VIRTUAL_ENV folder
            # if yes then do nothing
            # else deactivate
            parentdir="$(dirname "$VIRTUAL_ENV")"
            if [[ "$PWD"/ != "$parentdir"/* ]]; then
                deactivate
            fi
        fi
    }
fi

# NVM bash completion
if [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
    # macOS, installed via homebrew
    . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [ -s "$HOME/.nvm/bash_completion" ]; then
    # linux, installed via official script
    . "$HOME/.nvm/bash_completion"
fi

# NVM
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    . "/opt/homebrew/opt/nvm/nvm.sh"
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

elif [ -n "${BASH_VERSION}" ]; then
    # assume Bash

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

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bash_profile.post.bash" ]] && builtin source "$HOME/.fig/shell/bash_profile.post.bash"
