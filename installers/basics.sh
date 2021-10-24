#/bin/bash -ex

apt_install () {
    if ! command -v "$1" &> /dev/null; then
        sudo apt-get install -y "$1"
    fi
}

# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
        # xcode-select --install
        installers/homebrew.sh
    ;;
    Linux)
        # commands for Linux go here
        if command -v apt-get &> /dev/null; then
            sudo apt update
            sudo add-apt-repository universe
            apt_install bash-completion
            apt_install curl
            apt_install unzip  # needed by nerdfont installer
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
