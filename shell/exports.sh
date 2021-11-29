# Global settings
export PIP_REQUIRE_VIRTUALENV=true  # use --isolated to bypass
export PATH="$HOME/.local/bin:$PATH"  # pipx-installed binaries
export PATH="$PATH:$HOME/code/repos/dotfiles/shell/bin"  # dotfiles-bin

#Per-platform settings
case `uname` in
    Darwin)
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        export HOMEBREW_NO_ANALYTICS=1
        export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
        export PATH="$PATH:$HOME/.cargo/bin"
        export CLICOLOR=1  # Enable colors

        if [ `uname -m | grep arm64` ]; then
            export NVM_DIR="$HOME/.nvm"
        else
           export NVM_DIR=$HOME/.nvm_x86
        fi

    ;;
    Linux)
        # commands for Linux go here
        export PATH="$HOME/apps/vscode/bin:$PATH"
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        export KUBECONFIG="$HOME/.kube/config"
        export NVM_DIR="$HOME/.nvm"
        export PATH=$PATH:/usr/local/go/bin
        export PATH=$PATH:$HOME/.cargo/bin

    ;;
    FreeBSD)
        # commands for FreeBSD go here
    ;;
    MINGW64_NT-*)
        # commands for Git bash in Windows go here
    ;;
    *)
esac
