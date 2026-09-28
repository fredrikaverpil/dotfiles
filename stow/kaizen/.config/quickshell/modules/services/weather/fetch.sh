#!/usr/bin/env sh
# shellcheck shell=sh
# Fetches one MET forecast into a per-location cache and prints the Expires
# header, a newline, then the body. Usage: fetch.sh CACHE_DIR LAT LON URL UA
#
# Cache plus If-Modified-Since is required by MET's terms; -w prints Expires
# ahead of the body so the poll can honour it. The cache is per-location: one
# shared file would answer 304 after a location change and serve the previous
# city's forecast under the new name. A 304 touches the file it reused, so the
# 30-day sweep drops only locations left behind.
set -e
directory="$1"
cache="$directory/weather-$2_$3.json"
url="$4"
agent="$5"

mkdir -p "$directory"
if [ -f "$cache" ]; then set -- -z "$cache"; else set --; fi
curl -sf -m 15 -A "$agent" -o "$cache.new" "$@" -w '%header{expires}\n' "$url"
if [ -s "$cache.new" ]; then mv "$cache.new" "$cache"; else rm -f "$cache.new"; fi
if [ -f "$cache" ]; then touch "$cache"; fi
find "$directory" -maxdepth 1 -name 'weather-*.json' -mtime +30 -delete
cat "$cache"
