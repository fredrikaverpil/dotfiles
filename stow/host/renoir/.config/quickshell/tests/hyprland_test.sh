#!/usr/bin/env sh
# shellcheck shell=sh
set -e

config=${1:?missing hyprland.lua path}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

run_case() {
  name=$1
  scale=$2
  gdk_scale=$3
  monitor_config=$4
  home="$tmp/$name"

  mkdir -p "$home/.config/hypr" "$home/.local/state"
  printf '%s\n' "$monitor_config" > "$home/.config/hypr/monitors.lua"
  HOME="$home" lua tests/hyprland_test.lua "$config" "$scale" "$gdk_scale"
}

run_case valid 1.6 2 'return { scale = 1.6, gdkScale = 2 }'
run_case invalid 1 1 'return { scale = "invalid", gdkScale = 0 }'
