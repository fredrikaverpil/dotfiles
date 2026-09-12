#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Keep the theme-edit expression tied to the real persisted config.
grep -q '^        inactive-color ' ../niri/config.kdl

niri validate --config ../niri/config.kdl
printf 'PASS: compositor configuration contracts\n'
