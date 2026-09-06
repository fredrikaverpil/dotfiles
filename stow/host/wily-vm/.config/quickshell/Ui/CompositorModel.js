function dpms(niri, on) {
  return niri
    ? ["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]
    : ["hyprctl", "dispatch", on ? 'hl.dsp.dpms("on")' : 'hl.dsp.dpms("off")']
}

function closeWindow(niri) {
  return niri
    ? ["niri", "msg", "action", "close-window"]
    : ["hyprctl", "dispatch", "hl.dsp.window.close()"]
}

function focusWorkspace(niri, id) {
  return niri
    ? ["niri", "msg", "action", "focus-workspace", String(id)]
    : ["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "' + id + '" })']
}

function outputs(niri) {
  return niri
    ? ["niri", "msg", "-j", "focused-output"]
    : ["hyprctl", "-j", "monitors"]
}

function setScale(niri, name, mode, scale) {
  return niri
    ? ["niri", "msg", "output", name, "scale", String(scale)]
    : ["hyprctl", "eval", "hl.monitor({ output = " + JSON.stringify(name) +
        ", mode = " + JSON.stringify(mode) +
        ", position = \"auto\", scale = " + scale + " })"]
}

function scaleEdits(niri, scale, gdkScale) {
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

function layoutQuery(niri) {
  return niri
    ? ["niri", "msg", "-j", "keyboard-layouts"]
    : ["hyprctl", "-j", "devices"]
}

function setLayout(niri, index) {
  return niri
    ? ["niri", "msg", "action", "switch-layout", String(index)]
    : ["hyprctl", "switchxkblayout", "all", String(index)]
}

function nightlightBackend(niri) {
  return niri
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

if (typeof module !== "undefined") {
  module.exports = {
    dpms: dpms,
    closeWindow: closeWindow,
    focusWorkspace: focusWorkspace,
    outputs: outputs,
    setScale: setScale,
    scaleEdits: scaleEdits,
    layoutQuery: layoutQuery,
    setLayout: setLayout,
    nightlightBackend: nightlightBackend,
  }
}
