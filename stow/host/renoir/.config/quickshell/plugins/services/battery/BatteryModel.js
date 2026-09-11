var profiles = ["power-saver", "balanced", "performance"]

var dischargingIcons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
var chargingIcons = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]

function percent(fraction) {
  var value = Number(fraction)
  return isFinite(value) ? Math.round(Math.max(0, Math.min(1, value)) * 100) : 0
}

// Plugged in, but the charge threshold keeps the battery from charging.
function holding(battery, states, end) {
  if (battery.onBattery) return false
  if (battery.state === states.PendingCharge) return true
  var level = percent(battery.fraction)
  if (battery.state === states.FullyCharged) return level < 99
  return battery.state === states.Charging && end > 0 && level >= end
    && Math.abs(Number(battery.rate) || 0) <= 0.2
}

function status(battery, states, end) {
  if (holding(battery, states, end)) return "Holding"
  if (battery.onBattery) return "On battery"
  if (battery.state === states.FullyCharged || percent(battery.fraction) >= 100) return "Full"
  if (battery.state === states.Charging) return "Charging"
  return "Plugged in"
}

function icon(battery, states, end) {
  var index = Math.min(9, Math.floor(percent(battery.fraction) / 10))
  var charging = !battery.onBattery && !holding(battery, states, end)
  return (charging ? chargingIcons : dischargingIcons)[index]
}

function formatDuration(seconds) {
  var minutes = Math.round(Number(seconds) / 60)
  if (!(minutes > 0)) return ""
  var hours = Math.floor(minutes / 60)
  var rest = minutes % 60
  if (hours === 0) return rest + "m"
  return rest > 0 ? hours + "h " + rest + "m" : hours + "h"
}

function timeRemaining(battery, states, end) {
  var current = status(battery, states, end)
  if (current === "On battery") return formatDuration(battery.timeToEmpty)
  if (current === "Charging") return formatDuration(battery.timeToFull)
  return ""
}

function formatRate(watts) {
  var value = Math.abs(Number(watts))
  return value >= 0.05 ? value.toFixed(1) + " W" : "--"
}

function formatEnergy(now, full) {
  var current = Number(now)
  var capacity = Number(full)
  if (!(capacity > 0) || !isFinite(current)) return "--"
  return current.toFixed(1) + " / " + capacity.toFixed(1) + " Wh"
}

function formatHealth(supported, health) {
  var value = Number(health)
  return supported && value > 0 ? Math.round(value) + "%" : "--"
}

function formatThreshold(start, end) {
  if (!(end > 0)) return "--"
  return start > 0 && start < end ? start + "–" + end + "%" : end + "%"
}

// `grep -H .` output: one "<sysfs attribute>:<value>" line per readable file.
function parseSysfs(text) {
  var keys = {
    charge_control_start_threshold: "start",
    charge_control_end_threshold: "end",
    cycle_count: "cycles",
  }
  var result = { start: 0, end: 0, cycles: 0 }
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var separator = lines[i].indexOf(":")
    if (separator <= 0) continue
    var key = keys[lines[i].slice(0, separator)]
    var value = parseInt(lines[i].slice(separator + 1), 10)
    if (key && isFinite(value)) result[key] = value
  }
  return result
}

function loadedProfiles(raw) {
  var parsed = null
  try {
    parsed = JSON.parse(String(raw || ""))
  } catch (error) {
    parsed = null
  }
  var saved = parsed && typeof parsed === "object" ? parsed : {}
  return {
    ac: typeof saved.ac === "string" ? saved.ac : "",
    battery: typeof saved.battery === "string" ? saved.battery : "",
  }
}

function profilesText(saved) {
  return JSON.stringify({ version: 1, ac: saved.ac, battery: saved.battery }) + "\n"
}

function withProfile(saved, source, name) {
  return {
    ac: source === "ac" ? name : saved.ac,
    battery: source === "battery" ? name : saved.battery,
  }
}

function profileFor(saved, source, available) {
  var name = saved[source]
  if (available.indexOf(name) >= 0) return name
  return source === "ac" && available.indexOf("performance") >= 0 ? "performance" : "balanced"
}

// Notifies once per level crossing while discharging; charging resets it.
function lowBattery(level, discharging, notified, low, critical) {
  if (!discharging || level <= 0 || level > low) return { notified: "", notify: "" }
  var next = level <= critical || notified === "critical" ? "critical" : "low"
  return { notified: next, notify: next !== notified ? next : "" }
}
