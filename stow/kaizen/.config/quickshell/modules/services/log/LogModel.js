// Entries as `kaizen-log --json` prints them: { time, unit, level, message },
// time in milliseconds since the epoch, level WARN, ERROR or FATAL.

var LEVELS = ["WARN", "ERROR", "FATAL"];

// One line of output; null for anything else.
function parse(line) {
  var entry;
  try {
    entry = JSON.parse(line);
  } catch (e) {
    return null;
  }
  if (
    !entry ||
    typeof entry.time !== "number" ||
    typeof entry.unit !== "string" ||
    LEVELS.indexOf(entry.level) < 0 ||
    typeof entry.message !== "string"
  )
    return null;
  return {
    time: entry.time,
    unit: entry.unit,
    level: entry.level,
    message: entry.message,
  };
}

// The newest `limit` entries, oldest first.
function append(entries, more, limit) {
  return entries.concat(more).slice(-limit);
}

function isError(entry) {
  return entry.level !== "WARN";
}

function role(level) {
  return level === "WARN" ? "wood" : "rose";
}

function pad(value) {
  return (value < 10 ? "0" : "") + value;
}

function clock(time) {
  var date = new Date(time);
  return (
    pad(date.getHours()) +
    ":" +
    pad(date.getMinutes()) +
    ":" +
    pad(date.getSeconds())
  );
}

function line(entry) {
  return clock(entry.time) + " " + entry.unit + ": " + entry.message;
}
