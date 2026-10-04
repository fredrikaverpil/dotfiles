// One unit per target, so a target shows at most one source.
var PREFIX = "kaizen-mirror-";

// The unit's description carries both outputs, so the state survives shell restarts.
function description(source, target) {
  return "Mirror " + source + " onto " + target;
}

// Stops the target's mirror first: systemd-run refuses a unit name that is still loaded.
function startCommand(source, target) {
  return [
    "sh",
    "-c",
    'systemctl --user stop "$1"; exec systemd-run --user --collect --unit="$1" --description="$2" wl-mirror --fullscreen-output "$3" "$4"',
    "sh",
    PREFIX + target,
    description(source, target),
    target,
    source,
  ];
}

function stopCommand(target) {
  return ["systemctl", "--user", "stop", PREFIX + target];
}

function stopAllCommand() {
  return stopCommand("*");
}

function queryCommand() {
  return [
    "systemctl",
    "--user",
    "show",
    "--property=MainPID,Description",
    PREFIX + "*",
  ];
}

// `systemctl show` output, one blank-line-separated block per loaded unit.
function mirrors(raw) {
  return String(raw || "")
    .split("\n\n")
    .map(function (block) {
      var props = {};
      block.split("\n").forEach(function (line) {
        var at = line.indexOf("=");
        if (at > 0) props[line.slice(0, at)] = line.slice(at + 1);
      });
      var match = String(props.Description || "").match(
        /^Mirror (\S+) onto (\S+)$/,
      );
      var pid = Number(props.MainPID) || 0;
      return pid > 0 && match
        ? { pid: pid, source: match[1], target: match[2] }
        : null;
    })
    .filter(function (mirror) {
      return mirror;
    });
}

// An output is a source or a target, never both, so no mirror captures another.
function canMirror(list, source, target) {
  return (
    !!source &&
    !!target &&
    source !== target &&
    !list.some(function (mirror) {
      return mirror.target === source || mirror.source === target;
    })
  );
}

// Exits once any of the mirrors does.
function watchCommand(list) {
  return ["tail"]
    .concat(
      list.map(function (mirror) {
        return "--pid=" + mirror.pid;
      }),
    )
    .concat(["-f", "/dev/null"]);
}
