# Rust
if [ -f ~/.cargo/env ]; then
    . "$HOME/.cargo/env"
fi


# Nix
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix.sh
fi


# Linuxbrew
if [ -f ~/.linuxbrew/bin/brew ]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/fredrik/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi


# Pyenv + auto venv activation on cd
if [ -d ~/.pyenv ]; then
    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"

    function cd() {
    builtin cd "$@"

    if [[ -z "$VIRTUAL_ENV" ]] ; then
        ## If env folder is found then activate the vitualenv
        if [[ -d ./.venv ]] ; then
            source ./.venv/bin/activate
        fi
    else
        ## check the current folder belong to earlier VIRTUAL_ENV folder
        # if yes then do nothing
        # else deactivate
        parentdir="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "$parentdir"/* ]] ; then
            deactivate
        fi
    fi
    }
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

    # Starship
    if command -v starship &> /dev/null; then
        eval "$(starship init zsh)"
    fi

elif [ -n "${BASH_VERSION}" ]; then
    # assume Bash

    # Bash autocompletion
    if [ -f /etc/profile.d/bash_completion.sh ]; then
        source /etc/profile.d/bash_completion.sh
    fi

    # Starship
    if command -v starship &> /dev/null; then
        eval "$(starship init bash)"
    fi
fi

