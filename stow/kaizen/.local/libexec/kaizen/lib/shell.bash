# shellcheck shell=bash
# Sourced by the commands that act on kaizen-shell.service.

unit=kaizen-shell.service

# running: the shell.qml the unit's process runs, if it runs.
running() {
  local pid
  pid=$(systemctl --user show "$unit" -p MainPID --value)
  qs list --all -j | jq -r --argjson pid "${pid:-0}" '.[] | select(.pid == $pid) | .config_path'
}

# unlocked: fails unless the shell holds no lock. It answers "Not ready" while
# a reload runs, and for good once its config failed to load, when it has no
# lock surface either. The compositor keeps the lock after its client dies, so
# a restart while locked leaves the session unable to unlock.
unlocked() {
  local answer
  if [[ -z $(running) ]]; then
    return 0
  fi
  for _ in $(seq 25); do
    answer=$(timeout 2 kaizen ipc call lock isLocked 2>&1) || true
    case $answer in
    false) return 0 ;;
    true)
      echo "kaizen ${0##*/}: the session is locked" >&2
      return 1
      ;;
    esac
    sleep 0.2
  done
  if [[ $answer == "Not ready to accept queries yet." ]]; then
    return 0
  fi
  echo "kaizen ${0##*/}: the lock state is unknown: $answer" >&2
  return 1
}
