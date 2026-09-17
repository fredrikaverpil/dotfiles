var name = "niri"
var themeConfig = "/.config/niri/config.kdl"

function dpms(on) {
  return ["niri", "msg", "action", on ? "power-on-monitors" : "power-off-monitors"]
}

function closeWindow() { return ["niri", "msg", "action", "close-window"] }

// niri saves to screenshot-path and copies to the clipboard on its own.
function screenshot(mode) {
  return ["niri", "msg", "action",
    mode === "window" ? "screenshot-window" : "screenshot-screen"]
}

// Prints the picked color as #rrggbb, or nothing when cancelled.
function pickColor() {
  return ["sh", "-c", "niri msg pick-color | sed -n 's/^Hex: //p'"]
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
    scale: output.logical.scale || 1,
  }
}

function events() { return ["niri", "msg", "-j", "event-stream"] }

// niri cannot lock a window's aspect ratio, so a window of appId that ends up
// oblong gets its height set back to its width. state is {id, requested}; the
// requested height is remembered so a height niri will not grant is asked for
// once instead of on every event it provokes.
function keepSquare(raw, appId, state) {
  var event
  try { event = JSON.parse(String(raw || "")) } catch (error) { return state }
  if (event.WindowsChanged) {
    var match = (event.WindowsChanged.windows || []).filter(function(window) {
      return window && window.app_id === appId
    })[0]
    return { id: match ? match.id : 0, requested: 0 }
  }
  if (event.WindowOpenedOrChanged) {
    var opened = event.WindowOpenedOrChanged.window
    return opened && opened.app_id === appId ? { id: opened.id, requested: 0 } : state
  }
  if (event.WindowClosed) {
    return event.WindowClosed.id === state.id ? { id: 0, requested: 0 } : state
  }
  if (!event.WindowLayoutsChanged || !state.id) return state
  var changes = event.WindowLayoutsChanged.changes || []
  for (var i = 0; i < changes.length; i++) {
    if (changes[i][0] !== state.id) continue
    var size = (changes[i][1] || {}).window_size || []
    if (size[0] === size[1] || size[0] === state.requested) return state
    return {
      id: state.id,
      requested: size[0],
      command: ["niri", "msg", "action", "set-window-height", "--id", String(state.id), String(size[0])],
    }
  }
  return state
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
