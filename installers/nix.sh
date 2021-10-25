#/bin/bash -ex

# https://nixos.org/


# Per-platform settings
case `uname` in
    Darwin)
        # commands for macOS go here
    ;;
    Linux)
        # commands for Linux go here
        if [ ! -d ~/.nix-profile ]; then
            curl -L https://nixos.org/nix/install | sh
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
