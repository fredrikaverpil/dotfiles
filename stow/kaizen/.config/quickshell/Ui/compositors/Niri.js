var name = "niri";

function dpms(on) {
  return [
    "niri",
    "msg",
    "action",
    on ? "power-on-monitors" : "power-off-monitors",
  ];
}

function closeWindow() {
  return ["niri", "msg", "action", "close-window"];
}

// niri writes path asynchronously, after the action returns.
function screenshot(mode, path) {
  return [
    "niri",
    "msg",
    "action",
    mode === "window" ? "screenshot-window" : "screenshot-screen",
    "--path",
    path,
  ];
}

// Prints the picked color as #rrggbb, or nothing when cancelled.
function pickColor() {
  return ["sh", "-c", "niri msg pick-color | sed -n 's/^Hex: //p'"];
}

// niriConfig is NIRI_CONFIG, which niri prefers to the default path.
function configFile(home, niriConfig) {
  return niriConfig || home + "/.config/niri/config.kdl";
}

// Binds are the config lines carrying hotkey-overlay-title; the chord is the
// first word. Commented-out binds are skipped. A bind running
// `qs ipc call <target> <fn>` carries ipc "<target> <fn>"; one running a niri
// action without arguments carries action.
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
      var ipc = /^spawn\s+"qs"\s+"ipc"\s+"call"((?:\s+"[^"]*")+)\s*;$/.exec(
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

// A chord's keys as keycaps: Mod is Super, an XF86 key drops the prefix and
// its Audio or Mon group (XF86AudioMute is Mute).
function keycaps(chord) {
  return String(chord || "")
    .split("+")
    .filter(Boolean)
    .map(function (key) {
      return /^mod$/i.test(key)
        ? "Super"
        : key.replace(/^XF86(Audio|Mon)?/i, "");
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
  return ["kaizen-focus", pattern, "true"];
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

function events() {
  return ["niri", "msg", "-j", "event-stream"];
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

// niri has neither an aspect-ratio rule nor sticky windows (FAQ, issue 932),
// so the window of appId is kept square and moved to each workspace that gains
// focus. state is {id, requested, spaces}: the requested height is remembered
// so a height niri will not grant is asked for once instead of on every event
// it provokes, and spaces maps workspace ids to the indices actions take.
function pinWindow(raw, appId, state) {
  var event;
  try {
    event = JSON.parse(String(raw || ""));
  } catch (error) {
    return held(state);
  }
  if (event.WindowsChanged) {
    var match = (event.WindowsChanged.windows || []).filter(function (window) {
      return window && window.app_id === appId;
    })[0];
    return { id: match ? match.id : 0, requested: 0, spaces: state.spaces };
  }
  if (event.WindowOpenedOrChanged) {
    var opened = event.WindowOpenedOrChanged.window;
    if (!opened || opened.app_id !== appId) return held(state);
    return { id: opened.id, requested: 0, spaces: state.spaces };
  }
  if (event.WindowClosed) {
    return event.WindowClosed.id === state.id
      ? { id: 0, requested: 0, spaces: state.spaces }
      : held(state);
  }
  if (event.WorkspacesChanged) {
    var spaces = {};
    var list = event.WorkspacesChanged.workspaces || [];
    for (var space = 0; space < list.length; space++)
      spaces[list[space].id] = list[space].idx;
    return { id: state.id, requested: state.requested, spaces: spaces };
  }
  if (event.WorkspaceActivated) {
    var idx = (state.spaces || {})[event.WorkspaceActivated.id];
    if (!state.id || !event.WorkspaceActivated.focused || idx === undefined)
      return held(state);
    return command(state, [
      "niri",
      "msg",
      "action",
      "move-window-to-workspace",
      "--window-id",
      String(state.id),
      "--focus",
      "false",
      String(idx),
    ]);
  }
  if (!event.WindowLayoutsChanged || !state.id) return held(state);
  var changes = event.WindowLayoutsChanged.changes || [];
  for (var i = 0; i < changes.length; i++) {
    if (changes[i][0] !== state.id) continue;
    var size = (changes[i][1] || {}).window_size || [];
    if (size[0] === size[1] || size[0] === state.requested) return held(state);
    return command({ id: state.id, requested: size[0], spaces: state.spaces }, [
      "niri",
      "msg",
      "action",
      "set-window-height",
      "--id",
      String(state.id),
      String(size[0]),
    ]);
  }
  return held(state);
}

// The state without the command of the event that produced it, so an unchanged
// state is never mistaken for a new one to run.
function held(state) {
  return { id: state.id, requested: state.requested, spaces: state.spaces };
}

function command(state, argv) {
  return {
    id: state.id,
    requested: state.requested,
    spaces: state.spaces,
    command: argv,
  };
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
