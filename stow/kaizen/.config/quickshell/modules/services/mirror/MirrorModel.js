var UNIT = "kaizen-mirror";

// The unit's description carries both outputs, so the state survives shell restarts.
function description(source, target) {
  return "Mirror " + source + " onto " + target;
}

// Stops any running mirror first: systemd-run refuses a unit name that is still loaded.
function startCommand(source, target) {
  return [
    "sh",
    "-c",
    'systemctl --user stop "$1"; exec systemd-run --user --collect --unit="$1" --description="$2" wl-mirror --fullscreen-output "$3" "$4"',
    "sh",
    UNIT,
    description(source, target),
    target,
    source,
  ];
}

function stopCommand() {
  return ["systemctl", "--user", "stop", UNIT];
}

function queryCommand() {
  return [
    "systemctl",
    "--user",
    "show",
    "--property=MainPID,Description",
    UNIT,
  ];
}

// `systemctl show` output; an unloaded unit reports MainPID=0.
function state(raw) {
  var props = {};
  String(raw || "")
    .split("\n")
    .forEach(function (line) {
      var at = line.indexOf("=");
      if (at > 0) props[line.slice(0, at)] = line.slice(at + 1);
    });
  var pid = Number(props.MainPID) || 0;
  var match = String(props.Description || "").match(
    /^Mirror (\S+) onto (\S+)$/,
  );
  if (pid <= 0 || !match) return { pid: 0, source: "", target: "" };
  return { pid: pid, source: match[1], target: match[2] };
}
