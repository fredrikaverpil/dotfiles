# shellcheck shell=bash
# Sourced by the commands that act on kaizen-shell.service.

unit=kaizen-shell.service

# running: the shell.qml the unit's process runs, if it runs.
running() {
  local pid
  pid=$(systemctl --user show "$unit" -p MainPID --value)
  qs list --all -j | jq -r --argjson pid "${pid:-0}" '.[] | select(.pid == $pid) | .config_path'
}
