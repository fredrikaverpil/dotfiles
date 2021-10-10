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


# Bash completion
if [ -f /etc/profile.d/bash_completion.sh ]; then
    source /etc/profile.d/bash_completion.sh
fi


# Starship
if [ -f /usr/local/bin/starship ]; then
    eval "$(starship init bash)"
fi
