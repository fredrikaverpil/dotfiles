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
// The action closeWindow runs, as a bind names it.
var closeWindowAction = "window-close";

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
  return msg(closeWindowAction);
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

// umbriel/config.toml in the config dir.
function configFile(home, getenv) {
  return (
    (getenv("XDG_CONFIG_HOME") || home + "/.config") + "/umbriel/config.toml"
  );
}

// A TOML string's text: a literal '...' as is, a basic "..." unescaped.
function unquote(text) {
  if (text.charAt(0) === "'") return text.slice(1, -1);
  return text.slice(1, -1).replace(/\\(u[0-9a-fA-F]{4}|.)/g, function (_, c) {
    if (c.length > 1) return String.fromCharCode(parseInt(c.slice(1), 16));
    return { n: "\n", t: "\t", r: "\r", b: "\b", f: "\f" }[c] || c;
  });
}

var tomlString = /"(?:[^"\\]|\\.)*"|'[^']*'/g;

// The tables of a TOML file as {header: [line, ...]}, the lines before any
// header under "". A table's lines are the text up to the next header; an
// array of tables ([[name]]) collects under its name.
function tables(raw) {
  var header = "";
  var found = { "": [] };
  String(raw || "")
    .split("\n")
    .forEach(function (line) {
      var match = /^\s*\[\[?\s*([^\[\]]+?)\s*\]\]?\s*(#.*)?$/.exec(line);
      if (match) {
        header = match[1].replace(/\s*\.\s*/g, ".");
        found[header] = found[header] || [];
      } else {
        found[header].push(line);
      }
    });
  return found;
}

// The paths in a table's files = [...], which may span lines.
function includeFiles(lines) {
  var text = (lines || [])
    .map(function (line) {
      return line.replace(/^((?:[^#"']|"(?:[^"\\]|\\.)*"|'[^']*')*)#.*$/, "$1");
    })
    .join("\n");
  var match = /(?:^|\n)\s*files\s*=\s*\[([^\]]*)\]/.exec(text);
  return match ? (match[1].match(tomlString) || []).map(unquote) : [];
}

// Binds are the [keybinds] lines whose value ends in a comment, the label; a
// bind in a submap is left out. A bind spawning `kaizen ipc call <target>
// <fn>` carries ipc "<target> <fn>"; one running an action without
// arguments carries action.
function parseBinds(raw) {
  return (tables(raw).keybinds || [])
    .map(function (line) {
      return /^\s*("(?:[^"\\]|\\.)*"|[A-Za-z0-9_+-]+)\s*=\s*("(?:[^"\\]|\\.)*"|'[^']*'|\{.*\})\s*#\s*(.*\S)\s*$/.exec(
        line,
      );
    })
    .filter(function (match) {
      return match && !/^"?submap\[/.test(match[1]);
    })
    .map(function (match) {
      var chord = match[1].charAt(0) === '"' ? unquote(match[1]) : match[1];
      var bind = { chord: chord, label: match[3], enabled: true };
      var value = match[2];
      if (value.charAt(0) === "{") {
        var action =
          /(?:^\{|,)\s*action\s*=\s*("(?:[^"\\]|\\.)*"|'[^']*')/.exec(value);
        value = action ? action[1] : "";
      }
      var run = value ? unquote(value) : "";
      var ipc =
        /^spawn:\s*kaizen\s+ipc\s+call((?:\s+[A-Za-z0-9_-]+)+)\s*$/.exec(run);
      if (ipc) bind.ipc = ipc[1].trim().split(/\s+/).join(" ");
      if (/^[a-z][a-z-]*$/.test(run)) bind.action = run;
      return bind;
    });
}

// The binds of file and its includes in umbriel's merge order: the [include]
// files, then the [include.optional] ones, each expanded in place, then the
// file's own. ~ is home and other paths are relative to the including file; a
// file already read is skipped, as umbriel skips a cycle. read(path) returns a
// file's text, or null for a file it cannot read, which is skipped. A chord
// bound again overrides the earlier bind, so only the last is kept.
function readBinds(file, home, read, seen) {
  var visited = seen || {};
  if (visited[file]) return [];
  visited[file] = true;
  var raw = read(file);
  if (raw === null) return [];
  var dir = file.slice(0, file.lastIndexOf("/") + 1);
  var found = tables(raw);
  var binds = includeFiles(found.include)
    .concat(includeFiles(found["include.optional"]))
    .reduce(function (binds, path) {
      var resolved = /^~(\/|$)/.test(path)
        ? home + path.slice(1)
        : path.startsWith("/")
          ? path
          : dir + path;
      return binds.concat(readBinds(resolved, home, read, visited));
    }, [])
    .concat(parseBinds(raw));
  if (seen) return binds;
  var key = function (bind) {
    return bind.chord.toLowerCase().split("+").sort().join("+");
  };
  return binds.filter(function (bind, index) {
    return !binds.slice(index + 1).some(function (later) {
      return key(later) === key(bind);
    });
  });
}

function focusWorkspace(id, output) {
  return msg("workspace-switch:" + id + "/" + output);
}

// Focuses the active window whose app id matches pattern, else the first;
// does nothing when none does.
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
