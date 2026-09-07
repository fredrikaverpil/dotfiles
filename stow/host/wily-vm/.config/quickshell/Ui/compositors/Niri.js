.import "Scale.js" as Scale

var id = "niri"
var name = "niri"
var sessionVariable = "NIRI_SOCKET"
var workspaceComponent = "NiriWorkspaces.qml"
var scaleConfig = "/.config/niri/config.kdl"
// Demoting an exclusive panel loses its keyboard focus on niri.
var releaseExclusiveFocus = false

function dpms(on) {
  return ["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]
}

function closeWindow() { return ["niri", "msg", "action", "close-window"] }

function focusWorkspace(id) {
  return ["niri", "msg", "action", "focus-workspace", String(id)]
}

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
    refreshRate: mode.refresh_rate / 1000,
    scale: output.logical.scale,
  }
}

function setScale(name, mode, scale) {
  return ["niri", "msg", "output", name, "scale", String(scale)]
}

function scaleEdits(scale, gdkScale) {
  return [
    "-e", "s|^( *scale ).*|\\1" + scale + "|",
    "-e", "s|^( *GDK_SCALE ).*|\\1\"" + gdkScale + "\"|",
  ]
}

function cleanScale(scale, width, height) {
  var value = Number(scale)
  return isFinite(value) && value > 0 ? Scale.normalizeScale(value) : ""
}

function availableScales(scales, width, height) {
  return (scales || []).filter(function(scale) { return cleanScale(scale, width, height) !== "" }).map(String)
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
