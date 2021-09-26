# Per-platform settings
case `uname` in
    Darwin)
        # export PATH="$PATH:~/miniconda3/bin"
        export HOMEBREW_NO_ANALYTICS=1
        export PATH="/usr/local/opt/python@3.8/bin:$PATH"  # temporary until 'brew install python3' installs latest version
        export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
        export PATH="$PATH:$HOME/.cargo/bin"  # Rust
        export CLICOLOR=1  # Enable colors

    ;;
    Linux)
        # commands for Linux go here
        export PATH="$HOME/apps/vscode/bin:$PATH"
        export PYENV_ROOT="$HOME/.pyenv"  # pyenv
        export PATH="$PYENV_ROOT/bin:$PATH"  # pyenv
        export KUBECONFIG="$HOME/.kube/config"
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

# Global settings
export PIP_REQUIRE_VIRTUALENV=true  # use --isolated to bypass
export PATH="$HOME/.local/bin:$PATH"  # pipx-installed binaries
