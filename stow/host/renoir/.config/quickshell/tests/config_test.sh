#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

cd "$(dirname "$0")/.."

niri validate --config ../niri/config.kdl
printf 'PASS: compositor configuration contracts\n'
