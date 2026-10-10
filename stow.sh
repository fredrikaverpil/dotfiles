#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Symlinks the stow/ tree into $HOME: shared, platform, kaizen (kaizen hosts;
# unstowed elsewhere), then the optional host package and the stow/ trees of
# the host's private submodules, removes broken links into the repo left by
# files it moved or deleted, and reloads the user units on a kaizen host. Also
# what home-manager activation runs.
# --adopt absorbs a real file that replaced a managed symlink into the repo;
# --no-folding links files, not dirs, so other tools can write siblings.
# dir_links are the exception: linked as whole dirs, so new files in the repo
# show up without a restow.

case "$1" in
-h | --help)
  echo "usage: stow.sh [DOTFILES_DIR]    restow DOTFILES_DIR/stow (default: this script's directory) into \$HOME"
  exit 0
  ;;
esac

cd "${1:-$(dirname "$0")}"
dir_links=(.config/nvim-fredrik .config/nvim-simple .shell) # in stow/shared
dir_links_re="^($(IFS="|"; echo "${dir_links[*]//./\\.}"))"
stowed=()
stow_pkg() {
  stowed+=("$1/$2")
  local cmd=(stow --dir="$1" --target="$HOME" --restow --no-folding --adopt
    --ignore="$dir_links_re" "$2")
  echo "${cmd[*]}"
  "${cmd[@]}"
}
stow_pkg stow shared
for dir in "${dir_links[@]}"; do
  ln -sfn "$PWD/stow/shared/$dir" "$HOME/$dir"
done
stow_pkg stow/platform "$(uname -s)"
# kaizen's Nix module creates the marker.
if [ -e /etc/kaizen ]; then
  stow_pkg stow kaizen
else
  stow --dir=stow --target="$HOME" --delete --no-folding kaizen
fi
host="$(uname -n | cut -d. -f1)"
[ -d "stow/host/$host" ] && stow_pkg stow/host "$host"
for tree in nix/hosts/"$host"/*/stow; do
  [ -d "$tree" ] && stow_pkg "${tree%/stow}" stow
done
# Scans each top-level entry the packages hold, and removes the directories a
# removal leaves empty, up to that entry.
repo="$(pwd -P)"
for pkg in "${stowed[@]}"; do ls -A "$pkg"; done | sort -u |
  while IFS= read -r top; do
    [ -e "$HOME/$top" ] || [ -L "$HOME/$top" ] || continue
    find "$HOME/$top" -type l | while IFS= read -r link; do
      [ -e "$link" ] && continue
      case "$(readlink -m "$link")" in "$repo"/*) ;; *) continue ;; esac
      echo "rm $link"
      rm "$link"
      dir="$(dirname "$link")"
      while [ "$dir" != "$HOME" ] && [ "$dir" != "$HOME/$top" ] &&
        rmdir "$dir" 2>/dev/null; do
        dir="$(dirname "$dir")"
      done
    done
  done
# Stowed user units take effect on a reload, when a user manager runs.
if [ -e /etc/kaizen ]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  if systemctl --user show-environment >/dev/null 2>&1; then
    echo "systemctl --user daemon-reload"
    systemctl --user daemon-reload
  fi
fi
echo "stowed"
