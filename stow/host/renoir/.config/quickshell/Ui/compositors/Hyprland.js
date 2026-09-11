var id = "hyprland"
var name = "Hyprland"
var sessionVariable = "HYPRLAND_INSTANCE_SIGNATURE"
var workspaceComponent = "HyprlandWorkspaces.qml"
var themeConfig = "/.config/hypr/hyprland.lua"
// Start exclusive to acquire focus, then allow on-demand focus between panels.
var releaseExclusiveFocus = true

function dpms(on) {
  return ["hyprctl", "dispatch", on ? 'hl.dsp.dpms("on")' : 'hl.dsp.dpms("off")']
}

function closeWindow() {
  return ["hyprctl", "dispatch", "hl.dsp.window.close()"]
}

// Hyprland has no screenshot action, so grim needs the saving and copying
// niri does natively. Window geometry comes from the plain-text dump to avoid
// depending on jq, which is not declared anywhere in the flake.
function screenshot(mode) {
  var geometry = mode === "window"
    ? " -g \"$(hyprctl activewindow | awk '/^\\tat:/{a=$2} /^\\tsize:/{s=$2} " +
      "END{split(s, d, \",\"); print a \" \" d[1] \"x\" d[2]}')\""
    : ""
  return ["sh", "-c",
    "d=\"$HOME/Pictures/Screenshots\" && mkdir -p \"$d\" && " +
    "f=\"$d/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png\" && " +
    "grim" + geometry + " \"$f\" && wl-copy --type image/png < \"$f\""]
}

function focusWorkspace(id) {
  return ["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "' + id + '" })']
}

function outputs() { return ["hyprctl", "-j", "monitors"] }

function focusedMonitor(raw) {
  var monitors
  try { monitors = JSON.parse(String(raw || "")) } catch (error) { return null }
  if (!Array.isArray(monitors)) return null
  var monitor = monitors.find(function(m) { return m && m.focused })
    || monitors.find(function(m) { return m && Number(m.width) > 0 })
  if (!monitor) return null
  return {
    name: monitor.name,
    width: monitor.width,
    height: monitor.height,
  }
}

function themeEdits(palette) {
  var color = "rgb(" + String(palette.dim).replace("#", "") + ")"
  return ["-e", "s|^( *inactive_border = ).*|\\1\"" + color + "\",|"]
}

function layoutQuery() { return ["hyprctl", "-j", "devices"] }

function currentLayout(raw) {
  var parsed
  try { parsed = JSON.parse(String(raw || "")) } catch (error) { return -1 }
  var keyboards = parsed && Array.isArray(parsed.keyboards) ? parsed.keyboards : []
  var main = keyboards.find(function(keyboard) { return keyboard && keyboard.main }) || keyboards[0]
  var index = main && main.active_layout_index
  return Number.isInteger(index) && index >= 0 ? index : -1
}

function setLayout(index) { return ["hyprctl", "switchxkblayout", "all", String(index)] }
