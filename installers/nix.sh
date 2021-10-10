#/bin/bash -ex

# https://nixos.org/

if [ ! -d ~/.nix-profile ]; then
    curl -L https://nixos.org/nix/install | sh
fi