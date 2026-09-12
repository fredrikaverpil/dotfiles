#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

expected=${1:?usage: shell-smoke <hyprland|niri> [--panels]}
case "$expected" in
  hyprland | niri) ;;
  *)
    printf 'Unknown compositor: %s\n' "$expected" >&2
    exit 1
    ;;
esac
case "${2-}" in
  '' | --panels) ;;
  *)
    printf 'Unknown option: %s\n' "$2" >&2
    exit 1
    ;;
esac

systemctl --user is-active --quiet quickshell.service
pid=$(systemctl --user show quickshell.service --property=MainPID --value)
[[ "$pid" -gt 0 ]]

# Select the running service, not an arbitrary test instance or display. This
# also works over SSH without copying the whole desktop environment into it.
ipc() { timeout 10 qs ipc --pid "$pid" call "$@"; }
check() {
  local value
  value=$(ipc "$1" status)
  if ! jq -e --arg backend "$expected" "$2" <<<"$value" >/dev/null; then
    printf 'FAIL: %s status: %s\n' "$1" "$value" >&2
    return 1
  fi
  printf 'PASS: %s\n' "$1"
}

# shellcheck disable=SC2016 # $backend is a jq variable.
check compositor '.id == $backend and (.workspaceSource | endswith("Workspaces.qml"))'
check lock '(.locked | type) == "boolean" and .passwordPam == true'
check idle '(.enabled | type) == "boolean"'
check keyboard '.index >= 0 and .index < (.codes | length) and .code == .codes[.index]'
check nightlight '(.temperature | type) == "number" and (.mode == "on" or .mode == "off" or .mode == "auto")'
check media '(.hasPlayer | type) == "boolean" and (.hasMedia | type) == "boolean"'
check network '(.devices | type) == "array" and (.connection | type) == "object"'
check audio '(.volume | type) == "number" and (.muted | type) == "boolean"'
check battery '(.present | type) == "boolean" and (.profiles | type) == "array"'
check recording '(.recording | type) == "boolean" and (.monitor as $m | $m == "region" or any(.monitors[]; . == $m))'
case "$(ipc notifications dndState)" in
  on | off) printf 'PASS: notifications\n' ;;
  *)
    printf 'FAIL: notifications DND state\n' >&2
    exit 1
    ;;
esac
ipc tray list >/dev/null
printf 'PASS: tray\n'

# Opt-in: opens and then closes the display panel, also closing any competing
# panel. This exercises the real Process -> backend parser -> QML binding path.
if [[ "${2-}" == --panels ]]; then
  [[ "$(ipc lock isLocked)" == false ]]
  trap 'ipc display close' EXIT
  ipc display open
  ready=false
  for ((attempt = 0; attempt < 30; attempt++)); do
    if ipc display status | jq -e '(.monitor | length) > 0' >/dev/null; then
      ready=true
      break
    fi
    sleep 0.1
  done
  [[ "$ready" == true ]]
  printf 'PASS: live display query and bindings\n'
fi

started=$(systemctl --user show quickshell.service --property=ActiveEnterTimestamp --value)
# Quickshell can embed ANSI colours in journal messages, including the level.
log=$(journalctl --user -u quickshell.service --since "$started" --no-pager -o cat |
  jq -Rr 'gsub("\u001b\\[[0-9;]*m"; "")')
if grep -E '(^|[[:space:]])(ERROR|FATAL):|ReferenceError:|TypeError:|SyntaxError:|Failed to load configuration' <<<"$log"; then
  printf 'FAIL: Quickshell runtime errors since service start\n' >&2
  exit 1
fi
printf 'PASS: %s Quickshell smoke checks (hardware interactions not exercised)\n' "$expected"
