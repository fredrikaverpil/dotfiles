pragma Singleton

import QtQuick
import Quickshell

// The whole compositor coupling. Hyprland and niri both run this shell, and
// every command that differs between them is here -- nothing else in the tree
// branches on which one is up. The exception is the workspaces widget, whose
// two data sources are separate files because importing Quickshell.Hyprland
// under niri would connect to a socket that is not there.
Singleton {
  id: root

  // niri exports NIRI_SOCKET to what it spawns, and config.kdl passes the name
  // to `uwsm finalize` so it reaches the systemd user manager this unit starts
  // under. Without that export the shell silently decides it is on Hyprland.
  readonly property bool niri: !!Quickshell.env("NIRI_SOCKET")

  function dpms(on) {
    return niri
      ? ["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]
      // hyprctl dispatch takes Lua on 0.56; the hyprlang form "dpms off" is a
      // parse error that only shows up on hyprctl's stdout, which nothing reads.
      : ["hyprctl", "dispatch", on ? 'hl.dsp.dpms("on")' : 'hl.dsp.dpms("off")']
  }

  function closeWindow() {
    return niri
      ? ["niri", "msg", "action", "close-window"]
      : ["hyprctl", "dispatch", "hl.dsp.window.close()"]
  }

  function focusWorkspace(id) {
    return niri
      ? ["niri", "msg", "action", "focus-workspace", String(id)]
      : ["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "' + id + '" })']
  }

  // One output either way: niri answers with the focused one directly, while
  // hyprctl lists every monitor and marks it. Model.focusedMonitor() folds the
  // two shapes together.
  function outputs() {
    return niri
      ? ["niri", "msg", "-j", "focused-output"]
      : ["hyprctl", "-j", "monitors"]
  }

  function setScale(name, mode, scale) {
    return niri
      ? ["niri", "msg", "output", name, "scale", String(scale)]
      : ["hyprctl", "eval", "hl.monitor({ output = " + JSON.stringify(name) +
          ", mode = " + JSON.stringify(mode) +
          ", position = \"auto\", scale = " + scale + " })"]
  }

  // Where a scale chosen in the display panel is written so it survives a
  // restart. Both are rewritten line-by-line with sed; see the panel.
  readonly property string scaleConfig: Quickshell.env("HOME") +
    (niri ? "/.config/niri/config.kdl" : "/.config/hypr/monitors.lua")

  function scaleEdits(scale, gdkScale) {
    return niri
      ? [
          "-e", "s|^( *scale ).*|\\1" + scale + "|",
          "-e", "s|^( *GDK_SCALE ).*|\\1\"" + gdkScale + "\"|",
        ]
      : [
          "-e", "s|^local wily_monitor_scale = .*|local wily_monitor_scale = " + scale + "|",
          "-e", "s|^local wily_gdk_scale = .*|local wily_gdk_scale = " + gdkScale + "|",
        ]
  }

  // Nightlight. hyprsunset speaks Hyprland's own CTM protocol and nothing
  // else; niri implements wlr-gamma-control, which is what wl-gammarelay-rs
  // uses. Neither works on the other compositor.
  //
  // `pgrep -f`, not `-x`: /proc comm truncates to 15 characters, so the
  // process name reads "wl-gammarelay-r" and an exact match never hits.
  readonly property var nightlightBackend: niri
    ? ({
        running: "pgrep -f 'wl-gammarelay-rs run' >/dev/null",
        launch: "setsid uwsm-app -- wl-gammarelay-rs run",
        set: "busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q ",
        get: "busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature",
        probe: ["busctl", "--user", "get-property", "rs.wl-gammarelay", "/",
          "rs.wl.gammarelay", "Temperature"],
      })
    : ({
        running: "pgrep -x hyprsunset >/dev/null",
        launch: "setsid uwsm-app -- hyprsunset",
        set: "hyprctl hyprsunset temperature ",
        get: "hyprctl hyprsunset temperature",
        probe: ["hyprctl", "hyprsunset", "temperature"],
      })
}
