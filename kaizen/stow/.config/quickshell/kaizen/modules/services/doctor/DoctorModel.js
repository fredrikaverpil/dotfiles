// The report as `kaizen doctor --json` prints it: { findings, text }, each
// finding { source, id, level, unit, message, hint, count, first, last },
// times in milliseconds since the epoch, level ERROR or WARN, hint only with a
// fix.

var LEVELS = ["ERROR", "WARN"];

function isFinding(finding) {
  return (
    !!finding &&
    (finding.source === "log" || finding.source === "check") &&
    LEVELS.indexOf(finding.level) >= 0 &&
    typeof finding.unit === "string" &&
    typeof finding.message === "string" &&
    typeof finding.count === "number" &&
    typeof finding.first === "number" &&
    typeof finding.last === "number"
  );
}

// The report in the output; null for anything else.
function parse(output) {
  var report;
  try {
    report = JSON.parse(output);
  } catch (e) {
    return null;
  }
  if (
    !report ||
    !Array.isArray(report.findings) ||
    !report.findings.every(isFinding) ||
    typeof report.text !== "string"
  )
    return null;
  return { findings: report.findings, text: report.text };
}

function counts(findings) {
  var errors = findings.filter(function (finding) {
    return finding.level === "ERROR";
  }).length;
  return { errors: errors, warnings: findings.length - errors };
}

// "1 error, 2 warnings"; "" for none.
function summary(counts) {
  var parts = [];
  if (counts.errors > 0)
    parts.push(counts.errors + (counts.errors === 1 ? " error" : " errors"));
  if (counts.warnings > 0)
    parts.push(
      counts.warnings + (counts.warnings === 1 ? " warning" : " warnings"),
    );
  return parts.join(", ");
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

// When a logged finding happened: ×count when more than one, then the first
// time and, when it differs, the last. A check's finding is as old as the run:
// "".
function when(finding) {
  if (finding.source === "check") return "";
  var from = clock(finding.first);
  var to = clock(finding.last);
  return (
    (finding.count > 1 ? "×" + finding.count + " · " : "") +
    (from === to ? from : from + "–" + to)
  );
}

// What copying one finding puts on the clipboard: its message, then its hint.
function copyText(finding) {
  return finding.hint ? finding.message + "\n" + finding.hint : finding.message;
}

// Tells findings apart across runs, which replace the objects.
function key(finding) {
  return [finding.source, finding.id, finding.unit, finding.message].join("\n");
}
