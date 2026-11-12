#!/usr/bin/env sh
# shellcheck shell=sh
# Fetches SMHI's warnings into a cache and prints them. Usage: warnings.sh
# CACHE_DIR URL UA
#
# One file covers all of Sweden, so the cache is shared by every place, and
# being one file needs no sweep. SMHI's Last-Modified moves on every request,
# but its ETag holds: If-None-Match leaves an unchanged file at a 304. The ETag
# is kept only beside a cache it describes.
set -e
directory="$1"
cache="$directory/warnings-smhi.json"
etag="$cache.etag"
url="$2"
agent="$3"

mkdir -p "$directory"
[ -f "$cache" ] || rm -f "$etag"
curl -sf -m 15 -A "$agent" -o "$cache.new" --etag-compare "$etag" --etag-save "$etag" "$url"
if [ -s "$cache.new" ]; then mv "$cache.new" "$cache"; else rm -f "$cache.new"; fi
cat "$cache"
