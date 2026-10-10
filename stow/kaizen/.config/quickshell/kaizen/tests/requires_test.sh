#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Every program an argv head names is listed as a `cmd` in a requires file: a
# plugin's own or the core's for a plugin, the core's for the rest. Heads are
# taken from QML/JS arrays, the core's units and niri/config.kdl. Programs in
# shell strings and the libexec scripts are listed by hand.

cd "$(dirname "$0")/.."

units=../../systemd/user
hosts=../../../../host
# Present on every system.
base=" awk bash cat cut date find grep head kaizen ln ls mkdir mv readlink rm sed seq sh sleep sort tail touch tr "

# program ARGV...: the program, past timeout N, env VAR=… and xdg-terminal-exec's options.
program() {
  while (($# > 0)); do
    case ${1##*/} in
    timeout) shift 2 || return 0 ;;
    env | xdg-terminal-exec)
      shift
      while [[ ${1:-} == *=* || ${1:-} == -* ]]; do shift; done
      ;;
    *) break ;;
    esac
  done
  if (($# > 0)); then
    basename -- "$1"
  fi
}

# qml_heads FILE...: the program of each array after `command:`, `.command =`,
# `execDetached(` or `return`, up to its first non-literal element.
qml_heads() {
  local argv
  for file in "$@"; do
    tr '\n' ' ' <"$file" | grep -oE '(command *[:=]|execDetached\(|return) *\[ *"[^"]*"( *, *"[^"]*")*' || true
  done | while read -r array; do
    mapfile -t argv < <(grep -oE '"[^"]*"' <<<"$array" | tr -d '"')
    program "${argv[@]}"
  done
}

# unit_heads FILE...: the program of each ExecStart and ExecStartPre.
unit_heads() {
  local argv
  sed -nE 's/^ExecStart(Pre)?=[-@:+!]*//p' "$@" | while read -ra argv; do
    program "${argv[@]}"
  done
}

# check SCOPE REQUIRES PROGRAM...: fails on a program not listed in REQUIRES.
failed=false
check() {
  local scope=$1 requires=$2 listed files=(requires)
  shift 2
  if [[ -f $requires ]]; then files+=("$requires"); fi
  listed=" $(awk '$1 == "cmd" { printf "%s ", $2 }' "${files[@]}") "
  for name in $(printf '%s\n' "$@" | sort -u); do
    if [[ $base != *" $name "* && $listed != *" $name "* ]]; then
      printf 'FAIL: %s calls %s, not in %s\n' "$scope" "$name" "${requires:-requires}" >&2
      failed=true
    fi
  done
}

mapfile -t core_qml < <(find . -path ./plugins -prune -o -path ./tests -prune -o \( -name '*.qml' -o -name '*.js' \) -print)
mapfile -t core_units < <(grep -L '^ConditionPathExists=.*/kaizen/plugins/' "$units"/*.service)
mapfile -t core < <(
  qml_heads "${core_qml[@]}"
  unit_heads "${core_units[@]}"
  sed -nE 's/.*\bspawn +"([^"]+)".*/\1/p' ../../niri/config.kdl
)
check core "" "${core[@]}"

for dir in plugins/*/ "$hosts"/*/.config/kaizen/plugins/*/; do
  name=$(basename "$dir")
  mapfile -t files < <(find "$dir" \( -name '*.qml' -o -name '*.js' \) ! -name 'tst_*')
  mapfile -t plugin_units < <(grep -l "^ConditionPathExists=.*/kaizen/plugins/$name\.jsonc$" "$units"/*.service || true)
  mapfile -t calls < <(
    qml_heads "${files[@]}"
    if ((${#plugin_units[@]} > 0)); then unit_heads "${plugin_units[@]}"; fi
  )
  check "plugin $name" "${dir}requires" "${calls[@]}"
done

if $failed; then
  exit 1
fi
printf 'PASS: every argv head is in a requires file\n'
