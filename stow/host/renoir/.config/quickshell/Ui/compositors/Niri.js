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

// Absolute x and y, in the output's working area. `--x=` keeps a leading minus
// from being read as a flag; a bare negative number would mean a relative move.
function moveFloatingWindow(id, x, y) {
  return ["niri", "msg", "action", "move-floating-window", "--id", String(id), "--x=" + x, "--y=" + y]
}

// niri has neither an aspect-ratio rule nor sticky windows (FAQ, issue 932),
// so the window of appId is kept square and moved to each workspace that gains
// focus. state is {id, requested, spaces}: the requested height is remembered
// so a height niri will not grant is asked for once instead of on every event
// it provokes, and spaces maps workspace ids to the indices actions take.
function pinWindow(raw, appId, state) {
  var event
  try { event = JSON.parse(String(raw || "")) } catch (error) { return held(state) }
  if (event.WindowsChanged) {
    var match = (event.WindowsChanged.windows || []).filter(function(window) {
      return window && window.app_id === appId
    })[0]
    return { id: match ? match.id : 0, requested: 0, spaces: state.spaces }
  }
  if (event.WindowOpenedOrChanged) {
    var opened = event.WindowOpenedOrChanged.window
    if (!opened || opened.app_id !== appId) return held(state)
    return { id: opened.id, requested: 0, spaces: state.spaces }
  }
  if (event.WindowClosed) {
    return event.WindowClosed.id === state.id ? { id: 0, requested: 0, spaces: state.spaces } : held(state)
  }
  if (event.WorkspacesChanged) {
    var spaces = {}
    var list = event.WorkspacesChanged.workspaces || []
    for (var space = 0; space < list.length; space++) spaces[list[space].id] = list[space].idx
    return { id: state.id, requested: state.requested, spaces: spaces }
  }
  if (event.WorkspaceActivated) {
    var idx = (state.spaces || {})[event.WorkspaceActivated.id]
    if (!state.id || !event.WorkspaceActivated.focused || idx === undefined) return held(state)
    return command(state, ["niri", "msg", "action", "move-window-to-workspace",
      "--window-id", String(state.id), "--focus", "false", String(idx)])
  }
  if (!event.WindowLayoutsChanged || !state.id) return held(state)
  var changes = event.WindowLayoutsChanged.changes || []
  for (var i = 0; i < changes.length; i++) {
    if (changes[i][0] !== state.id) continue
    var size = (changes[i][1] || {}).window_size || []
    if (size[0] === size[1] || size[0] === state.requested) return held(state)
    return command({ id: state.id, requested: size[0], spaces: state.spaces },
      ["niri", "msg", "action", "set-window-height", "--id", String(state.id), String(size[0])])
  }
  return held(state)
}

// The state without the command of the event that produced it, so an unchanged
// state is never mistaken for a new one to run.
function held(state) {
  return { id: state.id, requested: state.requested, spaces: state.spaces }
}

function command(state, argv) {
  return { id: state.id, requested: state.requested, spaces: state.spaces, command: argv }
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
