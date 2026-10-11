// The report as `kaizen doctor --json` prints it: { findings, text }, each
// finding { source, level, unit, message, count, first, last }, times in
// milliseconds since the epoch, level ERROR or WARN.

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

function role(level) {
  return level === "WARN" ? "wood" : "rose";
}

function escape(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

// The text as rich text, each finding's level in its role's colour.
function html(text, palette) {
  var lines = text.split("\n").map(function (line) {
    var header = /^(ERROR|WARN)( .*)$/.exec(line);
    if (!header) return escape(line);
    return (
      '<span style="color: ' +
      palette[role(header[1])] +
      '">' +
      header[1] +
      "</span>" +
      escape(header[2])
    );
  });
  return '<div style="white-space: pre-wrap">' + lines.join("<br>") + "</div>";
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
