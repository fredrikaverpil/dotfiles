var name = "niri";

// Demoting an exclusive layer surface to on-demand loses its keyboard focus.
var releaseExclusiveFocus = false;
// A dead client's session lock holds, and a new client's lock replaces it.
var replacesDeadLock = true;
// A new window opens on the focused output, whichever output it asks for.
var opensOnFocusedOutput = true;
// move-floating-window is relative to the output's working area, which the
// bar's exclusive zone shortens at the top.
var floatsInWorkingArea = true;
// niri/kaizen.kdl's layer rule places the backdrop surface behind the
// workspaces, where the overview shows it.
var placesBackdrop = true;
var eventsComponent = "NiriEvents.qml";
var workspaceComponent = "NiriWorkspaces.qml";
var castComponent = "NiriCasts.qml";
var pinComponent = "NiriPin.qml";
// Under the shell's state dir, included by niri/kaizen.kdl.
var borderFile = "niri-colors.kdl";
// The action closeWindow runs, as a bind names it.
var closeWindowAction = "close-window";

function borderColors(palette) {
  return (
    'layout {\n    border {\n        active-color "' +
    palette.water +
    '"\n    }\n}\n'
  );
}

function dpms(on) {
  return [
    "niri",
    "msg",
    "action",
    on ? "power-on-monitors" : "power-off-monitors",
  ];
}

function closeWindow() {
  return ["niri", "msg", "action", closeWindowAction];
}

// niri writes path asynchronously, after the action returns.
function screenshot(path) {
  return ["niri", "msg", "action", "screenshot-screen", "--path", path];
}

function screenshotWindow(path) {
  return ["niri", "msg", "action", "screenshot-window", "--path", path];
}

// Prints the picked color as #rrggbb, or nothing when cancelled.
function pickColor() {
  return ["sh", "-c", "niri msg pick-color | sed -n 's/^Hex: //p'"];
}

// $NIRI_CONFIG, else niri/config.kdl in the config dir.
function configFile(home, getenv) {
  return (
    getenv("NIRI_CONFIG") ||
    (getenv("XDG_CONFIG_HOME") || home + "/.config") + "/niri/config.kdl"
  );
}

// Binds are the config lines carrying hotkey-overlay-title; the chord is the
// first word. Commented-out binds are skipped. A bind running
// `kaizen ipc call <target> <fn>` carries ipc "<target> <fn>"; one running a
// niri action without arguments carries action.
function parseBinds(raw) {
  return String(raw || "")
    .split("\n")
    .map(function (line) {
      return /^\s*([^\s\/]\S*)\s.*hotkey-overlay-title="([^"]*)"[^{]*(?:\{(.*)\})?/.exec(
        line,
      );
    })
    .filter(function (match) {
      return match && match[1] !== "spawn-at-startup";
    })
    .map(function (match) {
      var bind = { chord: match[1], label: match[2], enabled: true };
      var body = (match[3] || "").trim();
      var ipc = /^spawn\s+"kaizen"\s+"ipc"\s+"call"((?:\s+"[^"]*")+)\s*;$/.exec(
        body,
      );
      if (ipc)
        bind.ipc = ipc[1]
          .match(/"[^"]*"/g)
          .map(function (word) {
            return word.slice(1, -1);
          })
          .join(" ");
      var action = /^([a-z][a-z-]*)\s*;$/.exec(body);
      if (action) bind.action = action[1];
      return bind;
    });
}

// The binds of file with its includes expanded in place, resolved as niri does:
// ~ is home, other paths are relative to the including file, and nesting stops
// at 10 levels. read(path) returns a file's text, or null for a file it cannot
// read, which is skipped. A chord bound again overrides the earlier bind, so
// only the last is kept; niri ignores case and modifier order.
function readBinds(file, home, read, depth) {
  var raw = (depth || 0) < 10 ? read(file) : null;
  if (raw === null) return [];
  var dir = file.slice(0, file.lastIndexOf("/") + 1);
  // Splitting on a capture group alternates text and include paths.
  var binds = String(raw)
    .split(/^[ \t]*include[ \t][^"\n]*"([^"]*)".*$/m)
    .reduce(function (binds, part, index) {
      if (index % 2 === 0) return binds.concat(parseBinds(part));
      var path = /^~(\/|$)/.test(part)
        ? home + part.slice(1)
        : part.startsWith("/")
          ? part
          : dir + part;
      return binds.concat(readBinds(path, home, read, (depth || 0) + 1));
    }, []);
  if (depth) return binds;
  var key = function (bind) {
    return bind.chord.toLowerCase().split("+").sort().join("+");
  };
  return binds.filter(function (bind, index) {
    return !binds.slice(index + 1).some(function (later) {
      return key(later) === key(bind);
    });
  });
}

// focus-workspace acts on the focused output, so focus the target output first.
function focusWorkspace(id, output) {
  return [
    "sh",
    "-c",
    'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
    "sh",
    output,
    String(id),
  ];
}

// Focuses the most recently focused window whose app id matches pattern; does
// nothing when none does.
function focusApp(pattern) {
  return ["kaizen", "focus", pattern, "true"];
}

function focusMonitor(output) {
  return ["niri", "msg", "action", "focus-monitor", output];
}

function outputs() {
  return ["niri", "msg", "-j", "focused-output"];
}

// The same query, after focusing output. A window opens on the focused output
// and move-floating-window is relative to it, so a caller placing a window on
// output must both focus it and read its scale, in that order.
function focusedOutputOn(output) {
  return output
    ? [
        "sh",
        "-c",
        'niri msg action focus-monitor "$1" && niri msg -j focused-output',
        "sh",
        output,
      ]
    : outputs();
}

function focusedMonitor(raw) {
  var output;
  try {
    output = JSON.parse(String(raw || ""));
  } catch (error) {
    return null;
  }
  if (!output || !output.logical || !Number.isInteger(output.current_mode))
    return null;
  var mode = (output.modes || [])[output.current_mode];
  if (!mode) return null;
  return {
    name: output.name,
    width: mode.width,
    height: mode.height,
    scale: output.logical.scale || 1,
  };
}

// Absolute x and y, in the output's working area. `--x=` keeps a leading minus
// from being read as a flag; a bare negative number would mean a relative move.
function moveFloatingWindow(id, x, y) {
  return [
    "niri",
    "msg",
    "action",
    "move-floating-window",
    "--id",
    String(id),
    "--x=" + x,
    "--y=" + y,
  ];
}

function layoutQuery() {
  return ["niri", "msg", "-j", "keyboard-layouts"];
}

function currentLayout(raw) {
  var parsed;
  try {
    parsed = JSON.parse(String(raw || ""));
  } catch (error) {
    return -1;
  }
  var index = parsed && parsed.current_idx;
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

function setLayout(index) {
  return ["niri", "msg", "action", "switch-layout", String(index)];
}
