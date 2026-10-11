#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Installs kaizen as ~/.local/bin/kaizen, which precedes a Nix-built kaizen on
# PATH. Only from ~/.dotfiles: parallel sessions share ~/.local/bin, so a
# worktree runs `go build .` here and its ./kaizen by path.

cd "$(dirname "$0")"
top="$(git rev-parse --show-toplevel)"
if [ "$(cd "$top" && pwd -P)" != "$(cd ~/.dotfiles && pwd -P)" ]; then
  echo "kaizen/build.sh: installs only from ~/.dotfiles; in $top, run go build . and ./kaizen/kaizen" >&2
  exit 1
fi
dest="$HOME/.local/bin/kaizen"
mkdir -p "$(dirname "$dest")"
go build -o "$dest.tmp" .
# A rename replaces a link (the stowed dispatcher's) or a running binary in
# place of writing through it.
mv -f "$dest.tmp" "$dest"
echo "$dest"
