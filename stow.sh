#!/usr/bin/env bash
# shellcheck shell=bash
set -e

# Removes broken links into the repo left by files it moved or deleted, then
# symlinks the stow/ tree into $HOME: shared, platform, then the optional host
# package and the stow/ trees of the host's private submodules. Last, on a
# kaizen host `kaizen link` links kaizen/stow and reloads the user units, the
# host's included; elsewhere kaizen/stow is unstowed. Also what home-manager
# activation runs.
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
dir_links=(.claude/local-plugins .config/nvim-fredrik .config/nvim-simple .shell) # in stow/shared
dir_links_re="^($(IFS="|"; echo "${dir_links[*]//./\\.}"))"
pkgs=(stow/shared "stow/platform/$(uname -s)")
host="$(uname -n | cut -d. -f1)"
[ -d "stow/host/$host" ] && pkgs+=("stow/host/$host")
for tree in nix/hosts/"$host"/*/stow; do
  [ -d "$tree" ] && pkgs+=("$tree")
done
# Broken links go before stowing: stow refuses to replace a link it does not
# own, such as one into a package that moved. Scans each top-level entry the
# packages hold, and removes the directories a removal leaves empty, up to
# that entry.
repo="$(pwd -P)"
for pkg in "${pkgs[@]}"; do ls -A "$pkg"; done | sort -u |
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
for pkg in "${pkgs[@]}"; do
  cmd=(stow --dir="${pkg%/*}" --target="$HOME" --restow --no-folding --adopt
    --ignore="$dir_links_re" "${pkg##*/}")
  echo "${cmd[*]}"
  "${cmd[@]}"
done
for dir in "${dir_links[@]}"; do
  target="$HOME/$dir"
  # A real dir here, such as one stowed file by file, would get the link
  # inside it. One holding only links into the repo is replaced.
  if [ -d "$target" ] && [ ! -L "$target" ]; then
    foreign="$(find "$target" ! -type d | while IFS= read -r entry; do
      [ -L "$entry" ] && case "$(readlink -m "$entry")" in "$repo"/*) continue ;; esac
      echo "$entry"
    done)"
    if [ -n "$foreign" ]; then
      echo "skip $target: a dir holding entries outside the repo:" >&2
      echo "$foreign" >&2
      continue
    fi
    echo "rm -r $target"
    rm -r "$target"
  fi
  ln -sfn "$PWD/stow/shared/$dir" "$target"
done
# kaizen's Nix module creates the marker.
if [ -e /etc/kaizen ]; then
  kaizen link "$PWD"
else
  stow --dir=kaizen --target="$HOME" --delete --no-folding stow
fi
echo "stowed"
