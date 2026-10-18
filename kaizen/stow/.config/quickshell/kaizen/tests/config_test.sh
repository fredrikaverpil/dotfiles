#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

cd "$(dirname "$0")/.."

# kaizen.kdl alone, then each host's config.kdl beside its includes and
# kaizen.kdl, as stowed into ~/.config/niri.
niri validate --config ../../niri/kaizen.kdl
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for config in ../../../../../stow/host/*/.config/niri/config.kdl; do
  [ -e "$config" ] || continue
  host=$(basename "$(dirname "$(dirname "$(dirname "$config")")")")
  mkdir "$tmp/$host"
  cp -L "$(dirname "$config")"/*.kdl ../../niri/kaizen.kdl "$tmp/$host"
  niri validate --config "$tmp/$host/config.kdl"
done

# kaizen.toml alone, then each host's config.toml beside kaizen.toml and the
# host's xkb symbols, as stowed into ~/.config. An empty HOME leaves out the
# shell's colour file.
mkdir "$tmp/home"
HOME="$tmp/home" umbriel config validate -c ../../umbriel/kaizen.toml
for config in ../../../../../stow/host/*/.config/umbriel/config.toml; do
  [ -e "$config" ] || continue
  host=$(basename "$(dirname "$(dirname "$(dirname "$config")")")")
  mkdir -p "$tmp/umbriel-$host/umbriel"
  cp -L "$config" ../../umbriel/kaizen.toml "$tmp/umbriel-$host/umbriel"
  if [ -d "$(dirname "$(dirname "$config")")/xkb" ]; then
    cp -rL "$(dirname "$(dirname "$config")")/xkb" "$tmp/umbriel-$host"
  fi
  HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/umbriel-$host" umbriel config validate
done
printf 'PASS: compositor configuration contracts\n'

# kaizen/README.md rules with a mechanical check: the IPC column of the services
# table is the set of IpcHandler targets, and the shell writes only under the
# roots Ui/Paths.qml resolves.
doc=../../../../README.md
# shellcheck disable=SC2016
documented=$(grep -E '^\| [a-z ()]+ \| ' "$doc" | awk -F'|' '{print $6}' | grep -o '`[a-z]*`' | tr -d '`' | sort -u)
declared=$(grep -rho 'target: *"[a-z]*"' --include='*.qml' modules Ui shell.qml | grep -o '"[a-z]*"' | tr -d '"' | sort -u)
diff <(echo "$documented") <(echo "$declared") || {
  printf 'FAIL: IPC targets differ between kaizen/README.md and IpcHandler declarations\n' >&2
  exit 1
}
printf 'PASS: IPC targets match kaizen/README.md\n'

if grep -rn '/\.cache\|/\.local/state\|XDG_CACHE_HOME\|XDG_STATE_HOME' --include='*.qml' --include='*.js' --include='*.sh' --exclude=Paths.qml modules Ui shell.qml; then
  printf 'FAIL: write roots are resolved only in Ui/Paths.qml\n' >&2
  exit 1
fi
printf 'PASS: write roots resolve through Ui/Paths.qml\n'
