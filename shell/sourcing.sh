# Rust
if [ -f ~/.cargo/env ]; then
    . "$HOME/.cargo/env"
fi

# Linuxbrew
if [ -f ~/.linuxbrew/bin/brew ]; then
    eval "$(~/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/fredrik/.linuxbrew/bin/brew shellenv)"
    # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
