var name = "umbriel";

// A layer surface demoted from exclusive to on-demand keeps its keyboard focus.
var releaseExclusiveFocus = true;
// A dead client's session lock holds, and a new client's lock replaces it.
var replacesDeadLock = true;
// A new window opens on the focused output; a fullscreen request's output is
// ignored.
var opensOnFocusedOutput = true;
// window-move-to is relative to the output's usable area, which the bar's
// exclusive zone shortens at the top.
var floatsInWorkingArea = true;
var workspaceComponent = "UmbrielWorkspaces.qml";
var castComponent = "UmbrielCasts.qml";
// Under the shell's state dir, included by umbriel/kaizen.toml.
var borderFile = "umbriel-colors.toml";

// No action focuses an output by name; switching to its active workspace warps
// the cursor there, which focuses it. $1 is the output.
var focusOutput =
  'index=$(umbriel workspaces --json | jq -er --arg output "$1" ' +
  "'first(.[] | select(.output == $output and .active).index)') && " +
  'umbriel msg "workspace-switch:$index/$1" >/dev/null';

// The focused workspace's window, which keeps its place while a layer surface
// holds the keyboard.
var focusedWindow =
  "umbriel workspaces --json | jq -er " +
  "'first(.[] | select(.focused).focused_window | select(. != \"\"))'";

function borderColors(palette) {
  return '[colors.border]\nfocused = "' + palette.water + '"\n';
}

function msg(action) {
  return ["umbriel", "msg", action];
}

function dpms(on) {
  return msg(on ? "dpms-on" : "dpms-off");
}

function closeWindow() {
  return msg("window-close");
}

// grim has written path once the command exits.
function screenshot(mode, path) {
  return [
    "sh",
    "-c",
    mode === "window"
      ? "window=$(" + focusedWindow + ') && grim -T "$window" "$1"'
      : "output=$(umbriel outputs --json | jq -er " +
        "'first(.[] | select(.focused).name)') && " +
        'grim -o "$output" "$1"',
    "sh",
    path,
  ];
}

// Prints the picked color as #rrggbb, or nothing when cancelled.
function pickColor() {
  return [
    "sh",
    "-c",
    'point=$(slurp -p) && grim -g "$point" -t ppm - | ' +
      "magick - -format '#%[hex:p{0,0}]' info: | tr A-F a-f",
  ];
}

function configFile(home) {
  return home + "/.config/umbriel/config.toml";
}

// kaizen's umbriel binds carry no labels yet.
function readBinds() {
  return [];
}

function focusWorkspace(id, output) {
  return msg("workspace-switch:" + id + "/" + output);
}

// Focuses the most recently focused window whose app id matches pattern; does
// nothing when none does.
function focusApp(pattern) {
  return ["kaizen", "focus", pattern, "true"];
}

function focusMonitor(output) {
  return ["sh", "-c", focusOutput, "sh", output];
}

function outputs() {
  return ["umbriel", "outputs", "--json"];
}

// The same query, after focusing output. A window opens on the focused output
// and window-move-to is relative to it, so a caller placing a window on output
// must both focus it and read its scale, in that order.
function focusedOutputOn(output) {
  return output
    ? ["sh", "-c", focusOutput + " && umbriel outputs --json", "sh", output]
    : outputs();
}

function focusedMonitor(raw) {
  var list;
  try {
    list = JSON.parse(String(raw || ""));
  } catch (error) {
    return null;
  }
  var output = (Array.isArray(list) ? list : []).filter(function (output) {
    return output && output.focused;
  })[0];
  var mode = ((output && output.modes) || []).filter(function (mode) {
    return mode && mode.current;
  })[0];
  if (!mode) return null;
  return {
    name: output.name,
    width: mode.width,
    height: mode.height,
    scale: output.scale || 1,
  };
}

function events() {
  return ["umbriel", "subscribe", "windows"];
}

// Absolute x and y from the usable area's top-left corner.
function moveFloatingWindow(id, x, y) {
  return msg("window-move-to:top_left/" + x + "/" + y + "/" + id);
}

// The window rule for appId pins it and fixes its size, so only its id is
// followed, from each windows snapshot. state is {id, requested, spaces}, as
// Niri.pinWindow keeps it.
function pinWindow(raw, appId, state) {
  var event;
  try {
    event = JSON.parse(String(raw || ""));
  } catch (error) {
    event = null;
  }
  var held = { id: state.id, requested: state.requested, spaces: state.spaces };
  if (!event || event.event !== "windows" || !Array.isArray(event.data))
    return held;
  var match = event.data.filter(function (window) {
    return window && window.app_id === appId;
  })[0];
  held.id = match ? match.id : 0;
  return held;
}

function layoutQuery() {
  return ["umbriel", "keyboard-layouts", "--json"];
}

function currentLayout(raw) {
  var parsed;
  try {
    parsed = JSON.parse(String(raw || ""));
  } catch (error) {
    return -1;
  }
  var index = parsed && parsed.current_index;
  return Number.isInteger(index) && index >= 0 ? index : -1;
}

// Names in xkb order, from the compositor's layout list.
function layoutNames(raw) {
  var parsed;
  try {
    parsed = JSON.parse(String(raw || ""));
  } catch (error) {
    return [];
  }
  var names = parsed && parsed.names;
  return Array.isArray(names) ? names.map(String) : [];
}

// umbriel only steps to the next layout, so this steps from current to index
// among count layouts.
function setLayout(index, current, count) {
  var steps = (((index - current) % count) + count) % count;
  return [
    "sh",
    "-c",
    'for _ in $(seq "$1"); do umbriel msg keyboard-layout-next >/dev/null || exit; done',
    "sh",
    String(steps),
  ];
}
