#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Keep the backend's scale-edit expressions tied to the real persisted configs.
grep -q '^local wily_monitor_scale = ' ../hypr/monitors.lua
grep -q '^local wily_gdk_scale = ' ../hypr/monitors.lua
grep -q '^    scale ' ../niri/config.kdl
grep -q '^    GDK_SCALE ' ../niri/config.kdl
grep -q '^        inactive-color ' ../niri/config.kdl
grep -q '^      inactive_border = ' ../hypr/hyprland.lua

tests/hyprland_test.sh ../hypr/hyprland.lua
niri validate --config ../niri/config.kdl
printf 'PASS: compositor configuration contracts\n'
