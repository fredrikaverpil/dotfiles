
# https://cli.github.com/manual/installation


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here

    ;;
    Linux)
        # commands for Linux go here
        if ! command -v curl &> /dev/null
        then
            sudo apt update
            sudo apt install -y curl
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