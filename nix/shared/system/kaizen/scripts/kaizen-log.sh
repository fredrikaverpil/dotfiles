#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# The units log at priority 6 with the level in the text: Quickshell and dcal
# lead with it (`  WARN scene:`), other tools start with it after at most a Go
# log timestamp and a word (`error: …`, `… systray error: …`). systemd's own
# lines about the units carry a real priority.
# shellcheck disable=SC2016
filter='
  def hex: "0123456789abcdef"[.:. + 1];
  # journalctl sends a message with control bytes (ANSI colours) as a byte array.
  def text:
    if type == "array" then map("%" + ((. / 16 | floor) | hex) + ((. % 16) | hex)) | add | @urid
    else . // "" end
    | gsub("\u001b\\[[0-9;]*m"; "");
  def level:
    capture("^\\s*(?<l>DEBUG|INFO|WARN|ERROR|FATAL)\\b").l
    // (select(test("^(\\d{4}/\\d\\d/\\d\\d \\d\\d:\\d\\d:\\d\\d )?(\\S+ )?(warn(ing)?|error|fatal|crit(ical)?|panic)\\b"; "i")) | "WARN")
    // "INFO";
  (.MESSAGE | text) as $m
  | select((.PRIORITY // "6" | tonumber) <= 4 or ($m | level | IN("WARN", "ERROR", "FATAL")))
  | (.__REALTIME_TIMESTAMP | tonumber / 1000000 | strflocaltime("%b %d %T")) + " "
    + (.USER_UNIT // ._SYSTEMD_USER_UNIT // .SYSLOG_IDENTIFIER | sub("\\.service$"; ""))
    + ": " + ($m | sub("^\\s+"; ""))
'

journalctl --user --unit 'kaizen-*' --boot --lines all --output json --no-pager "$@" |
  jq --unbuffered -r "$filter"
