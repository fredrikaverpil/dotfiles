#/bin/bash -ex

# https://github.com/tmuxinator/tmuxinator

# Per-platform settings
case $(uname) in
Darwin)
    # commands for macOS go here

    # tmux plugin manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    if ! command -v tmuxinator &>/dev/null; then
        brew install tmuxinator
    fi

    ;;
Linux)
    # commands for Linux go here

    # tmux plugin manager
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    if ! command -v gem &>/dev/null; then
        sudo apt install ruby
    fi

    if ! command -v tmuxinator &>/dev/null; then
        sudo gem install tmuxinator

        # zsh completion
        sudo wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh -O /usr/local/share/zsh/site-functions/_tmuxinator
    fi
    ;;
FreeBSD)
    # commands for FreeBSD go here
    ;;
MINGW64_NT-*)
    # commands for Git bash in Windows go here
    ;;
*) ;;
esac
