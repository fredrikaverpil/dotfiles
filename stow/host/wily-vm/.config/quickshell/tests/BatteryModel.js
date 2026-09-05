// Dummy subject for the test examples beside it. Pure data in, data out, in
// the same style as the real plugins/**/[Nn]*Model.js files: `var`, no ESM, and
// a module.exports guard so the file loads both in QML and in a JS runtime.
//
// Nothing in the shell imports this. Delete it once a real model is under test.

var ICONS = ["󰂎", "󰁺", "󰁼", "󰁾", "󰂀", "󰂂", "󰁹"]

function iconFor(percent, charging) {
  if (charging) return "󰂄"
  var value = Number(percent)
  if (!isFinite(value)) return ICONS[0]
  var index = Math.round(Math.max(0, Math.min(100, value)) / 100 * (ICONS.length - 1))
  return ICONS[index]
}

// Anything at or below this reads as a warning in the bar.
var LOW_THRESHOLD = 15

// Number(null) is 0, which isFinite accepts -- an unknown level would read as
// a flat battery. Unknown has to be rejected before the numeric conversion.
function isLow(percent, charging) {
  if (percent === null || percent === undefined || percent === "") return false
  var value = Number(percent)
  return !charging && isFinite(value) && value <= LOW_THRESHOLD
}

function label(percent, charging) {
  var value = Number(percent)
  if (!isFinite(value)) return "--%"
  return Math.round(value) + "%" + (charging ? " ↑" : "")
}

if (typeof module !== "undefined") {
  module.exports = {
    iconFor: iconFor,
    isLow: isLow,
    label: label,
    LOW_THRESHOLD: LOW_THRESHOLD
  }
}
