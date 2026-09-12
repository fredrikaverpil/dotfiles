#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Restarts the running shell, measures it under fixed conditions, appends a row
# to nix/hosts/<host>/shell-perf.tsv and compares it with the previous row
# measured on the same Quickshell build and outputs.
#
#   shell-perf                   startup, idle and panel costs (~10 min)
#   shell-perf --soak H [PANEL]  memory growth over H hours, PANEL held open

warmup=120
idle_seconds=300
panel_seconds=20
panels=(display network bluetooth audio weather media battery)

mode=bench
soak_hours=-
soak_panel=-
case "${1-}" in
  '') ;;
  --soak)
    [[ "${2-}" =~ ^[0-9]+([.][0-9]+)?$ ]] || {
      printf 'usage: shell-perf [--soak HOURS [PANEL]]\n' >&2
      exit 1
    }
    mode=soak
    soak_hours=$2
    soak_panel=${3:--}
    ;;
  *)
    printf 'usage: shell-perf [--soak HOURS [PANEL]]\n' >&2
    exit 1
    ;;
esac

host=$(hostname -s)
root=$(git rev-parse --show-toplevel)
log="$root/nix/hosts/$host/shell-perf.tsv"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
prop() { systemctl --user show quickshell.service --property="$1" --value; }
ipc() { timeout 10 qs ipc --pid "$pid" call "$@"; }
mb() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1048576 }'; }
pss() { awk '/^Pss:/ { printf "%.1f", $2 / 1024 }' "/proc/$pid/smaps_rollup"; }
# Busy and total jiffies of all CPUs.
jiffies() { awk '/^cpu / { t = 0; for (i = 2; i <= NF; i++) t += $i; print t - $5 - $6, t }' /proc/stat; }
# CPU seconds per minute used by the service cgroup (children included) and
# whole-system busy % between two samples.
rates() {
  awk -v c0="$1" -v c1="$2" -v s="$3" -v j0="$4" -v j1="$5" 'BEGIN {
    split(j0, a, " "); split(j1, b, " ")
    printf "%.3f %.1f\n", (c1 - c0) / 1e9 / (s / 60), (b[1] - a[1]) * 100 / (b[2] - a[2])
  }'
}

# Conditions every row is measured under.
[[ "$(cat /sys/class/power_supply/AC/online)" == 1 ]] || fail 'not on AC power'
[[ "$(powerprofilesctl get)" == balanced ]] || fail 'power profile is not balanced'
systemctl --user is-active --quiet quickshell.service || fail 'quickshell.service is not active'
pid=$(prop MainPID)
[[ "$(ipc lock isLocked)" == false ]] || fail 'session is locked'
load=$(cut -d' ' -f1 /proc/loadavg)
awk -v l="$load" 'BEGIN { exit !(l < 1.5) }' || fail "system load $load; wait until it is idle"

idle_was=$(ipc idle status | jq -r .enabled)
open_panel=
cleanup() {
  [[ -n "$open_panel" ]] && ipc "$open_panel" close >/dev/null 2>&1 || true
  [[ "$idle_was" == true ]] && ipc idle enable >/dev/null 2>&1 || true
}
trap cleanup EXIT
# Persisted, so the restarted shell starts with idle locking off.
ipc idle disable >/dev/null

printf 'Hands off the machine until the run ends.\n'
started=$(date +%s%N)
systemctl --user restart quickshell.service
pid=$(prop MainPID)
until ipc system status >/dev/null 2>&1; do
  (($(date +%s%N) - started < 30000000000)) || fail 'shell did not answer IPC within 30 s'
  sleep 0.05
done
startup_ms=$((($(date +%s%N) - started) / 1000000))

exe=$(readlink "/proc/$pid/exe")
quickshell=$(sed -E 's|^/nix/store/([a-z0-9]{7})[a-z0-9]*-([^/]*)/.*|\1-\2|' <<<"$exe")
outputs=$(niri msg --json outputs | jq -r '[.[] | "\(.name):\(.logical.width)x\(.logical.height)@\(.logical.scale)"] | sort | join(",")')
commit=$(git rev-parse --short HEAD)
[[ -z "$(git status --porcelain -- "$root/stow/host/$host")" ]] || commit="$commit-dirty"

printf 'Warming up for %s s\n' "$warmup"
sleep "$warmup"

idle_cpu=- idle_pss=- panels_cpu=- panels_pss=- soak_slope=-
if [[ "$mode" == bench ]]; then
  printf 'Measuring idle for %s s\n' "$idle_seconds"
  c0=$(prop CPUUsageNSec) j0=$(jiffies)
  sleep "$idle_seconds"
  read -r idle_cpu busy < <(rates "$c0" "$(prop CPUUsageNSec)" "$idle_seconds" "$j0" "$(jiffies)")
  idle_pss=$(pss)

  printf 'Opening %s panels for %s s each\n' "${#panels[@]}" "$panel_seconds"
  c0=$(prop CPUUsageNSec) j0=$(jiffies) t0=$(date +%s)
  for panel in "${panels[@]}"; do
    open_panel=$panel
    ipc "$panel" open >/dev/null
    sleep "$panel_seconds"
    ipc "$panel" close >/dev/null
    open_panel=
  done
  sleep 10
  read -r panels_cpu panels_busy < <(rates "$c0" "$(prop CPUUsageNSec)" "$(($(date +%s) - t0))" "$j0" "$(jiffies)")
  panels_pss=$(pss)
  busy=$(awk -v a="$busy" -v b="$panels_busy" 'BEGIN { printf "%.1f", (a > b ? a : b) }')
else
  if [[ "$soak_panel" != - ]]; then
    open_panel=$soak_panel
    ipc "$soak_panel" open >/dev/null
  fi
  seconds=$(awk -v h="$soak_hours" 'BEGIN { printf "%d", h * 3600 }')
  printf 'Soaking for %s h, sampling PSS every minute\n' "$soak_hours"
  c0=$(prop CPUUsageNSec) j0=$(jiffies) t0=$(date +%s)
  samples=
  while (($(date +%s) - t0 < seconds)); do
    samples+="$(($(date +%s) - t0)) $(pss)"$'\n'
    sleep 60
  done
  read -r idle_cpu busy < <(rates "$c0" "$(prop CPUUsageNSec)" "$(($(date +%s) - t0))" "$j0" "$(jiffies)")
  idle_pss=$(pss)
  # Least-squares PSS growth, MB per hour.
  soak_slope=$(awk 'NF == 2 { n++; x = $1 / 3600; sx += x; sy += $2; sxy += x * $2; sxx += x * x }
    END { d = n * sxx - sx * sx; printf "%.2f", (d > 0 ? (n * sxy - sx * sy) / d : 0) }' <<<"$samples")
fi

peak=$(mb "$(prop MemoryPeak)")
threads=$(awk '/^Threads:/ { print $2 }' "/proc/$pid/status")

columns='date commit mode quickshell outputs startup_ms idle_cpu_s_min idle_pss_mb panels_cpu_s_min panels_pss_mb peak_mb threads system_busy_pct soak_hours soak_panel soak_slope_mb_h'
[[ -s "$log" ]] || tr ' ' '\t' <<<"$columns" >"$log"
row=$(printf '%s\t' "$(date -Iseconds)" "$commit" "$mode" "$quickshell" "$outputs" "$startup_ms" \
  "$idle_cpu" "$idle_pss" "$panels_cpu" "$panels_pss" "$peak" "$threads" "$busy" \
  "$soak_hours" "$soak_panel" "$soak_slope")
row=${row%$'\t'}

# Previous comparable row: same mode, build, outputs and soak panel.
awk -F'\t' -v OFS='\t' -v row="$row" '
  BEGIN { split(row, now, "\t") }
  NR == 1 { for (i = 1; i <= NF; i++) name[i] = $i; next }
  $3 == now[3] && $4 == now[4] && $5 == now[5] && $15 == now[15] { split($0, prev, "\t") }
  END {
    if (!length(prev)) { print "No comparable previous row."; exit }
    printf "Compared with %s (%s):\n", prev[2], prev[1]
    for (i = 6; i <= 16; i++) if (now[i] != "-" && i != 14 && i != 15)
      printf "  %-18s %10s -> %-10s %+.3f\n", name[i], prev[i], now[i], now[i] - prev[i]
  }' "$log"
printf '%s\n' "$row" >>"$log"
awk -v b="$busy" 'BEGIN { exit !(b > 10) }' &&
  printf 'WARN: system was %s%% busy during measurement; the row is noisy\n' "$busy"
printf 'Appended to %s\n' "${log#"$root"/}"
