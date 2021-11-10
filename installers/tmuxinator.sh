#/bin/bash -ex

# https://github.com/tmuxinator/tmuxinator


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        brew install tmuxinator
    ;;
    Linux)
        # commands for Linux go here
        if ! command -v tmuxinator &> /dev/null; then

            if ! command -v gem &> /dev/null; then
                sudo apt install ruby
            fi

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
    *)
esac