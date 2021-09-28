#/bin/bash -ex

# https://github.com/pypa/pipx

# Per-platform settings
case `uname` in
    Darwin)
        # commands for Linux go here
    ;;
    Linux)
        # commands for Linux go here
        if ! command -v pipx &> /dev/null; then
            PIP_REQUIRE_VIRTUALENV=false $HOME/.pyenv/versions/3.9.7/bin/python -m pip install -U pipx
            sudo ln -s $HOME/.pyenv/versions/3.9.7/bin/pipx /usr/bin/pipx
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
