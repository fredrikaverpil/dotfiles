
var ICONS = ["󰂎", "󰁺", "󰁼", "󰁾", "󰂀", "󰂂", "󰁹"]

function iconFor(percent, charging) {
  if (charging) return "󰂄"
  var value = Number(percent)
  if (!isFinite(value)) return ICONS[0]
  var index = Math.round(Math.max(0, Math.min(100, value)) / 100 * (ICONS.length - 1))
  return ICONS[index]
}

var LOW_THRESHOLD = 15

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
