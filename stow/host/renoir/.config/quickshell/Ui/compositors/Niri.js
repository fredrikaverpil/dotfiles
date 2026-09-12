var id = "niri"
var name = "niri"
var sessionVariable = "NIRI_SOCKET"
var workspaceComponent = "NiriWorkspaces.qml"
var themeConfig = "/.config/niri/config.kdl"
// Demoting an exclusive panel loses its keyboard focus on niri.
var releaseExclusiveFocus = false

function dpms(on) {
  return ["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]
}

function closeWindow() { return ["niri", "msg", "action", "close-window"] }

// niri saves to screenshot-path and copies to the clipboard on its own.
function screenshot(mode) {
  return ["niri", "msg", "action",
    mode === "window" ? "screenshot-window" : "screenshot-screen"]
}

// focus-workspace acts on the focused output, so focus the target output first.
function focusWorkspace(id, output) {
  return ["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
    "sh", output, String(id)]
}

function focusMonitor(output) { return ["niri", "msg", "action", "focus-monitor", output] }

function outputs() { return ["niri", "msg", "-j", "focused-output"] }

function focusedMonitor(raw) {
  var output
  try { output = JSON.parse(String(raw || "")) } catch (error) { return null }
  if (!output || !output.logical || !Number.isInteger(output.current_mode)) return null
  var mode = (output.modes || [])[output.current_mode]
  if (!mode) return null
  return {
    name: output.name,
    width: mode.width,
    height: mode.height,
  }
}

function themeEdits(palette) {
  return ["-e", "s|^( *inactive-color ).*|\\1\"" + palette.dim + "\"|"]
}

function layoutQuery() { return ["niri", "msg", "-j", "keyboard-layouts"] }

function currentLayout(raw) {
  var parsed
  try { parsed = JSON.parse(String(raw || "")) } catch (error) { return -1 }
  var index = parsed && parsed.current_idx
  return Number.isInteger(index) && index >= 0 ? index : -1
}

function setLayout(index) {
  return ["niri", "msg", "action", "switch-layout", String(index)]
}
