#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

cd "$(dirname "$0")/.."

niri validate --config ../niri/config.kdl
printf 'PASS: compositor configuration contracts\n'

# docs/kaizen/README.md rules with a mechanical check: the IPC column of the services
# table is the set of IpcHandler targets, and the shell writes only under the
# roots Ui/Paths.qml resolves.
doc=../../../../docs/kaizen/README.md
# shellcheck disable=SC2016
documented=$(grep -E '^\| [a-z ()]+ \| ' "$doc" | awk -F'|' '{print $6}' | grep -o '`[a-z]*`' | tr -d '`' | sort -u)
declared=$(grep -rho 'target: *"[a-z]*"' --include='*.qml' modules Ui shell.qml | grep -o '"[a-z]*"' | tr -d '"' | sort -u)
diff <(echo "$documented") <(echo "$declared") || {
  printf 'FAIL: IPC targets differ between docs/kaizen/README.md and IpcHandler declarations\n' >&2
  exit 1
}
printf 'PASS: IPC targets match docs/kaizen/README.md\n'

if grep -rn '/\.cache\|/\.local/state\|XDG_CACHE_HOME\|XDG_STATE_HOME' --include='*.qml' --include='*.js' --include='*.sh' --exclude=Paths.qml modules Ui shell.qml; then
  printf 'FAIL: write roots are resolved only in Ui/Paths.qml\n' >&2
  exit 1
fi
printf 'PASS: write roots resolve through Ui/Paths.qml\n'
