// Deliberately kept beside Omarchy's notification helper at the same path.
// This lean version owns only state that remains useful after a notification's
// D-Bus object is released; restart persistence and image archival are deferred.

function asString(value) {
  return value === undefined || value === null ? "" : String(value)
}

function iconSource(icon) {
  var value = asString(icon)
  if (!value) return ""
  if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
  if (value.charAt(0) === "/") return "file://" + value
  return value
}

function snapshotOf(notification, timestamp) {
  return {
    app: asString(notification.appName),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    urgency: Number(notification.urgency),
    timestamp: timestamp === undefined ? Date.now() : timestamp
  }
}

function durationFor(notification, lowUrgency, criticalUrgency) {
  if (notification.urgency === criticalUrgency || notification.resident) return 0

  var requested = Number(notification.expireTimeout)
  if (!isFinite(requested) || requested <= 0) requested = 0

  var minimum = notification.urgency === lowUrgency ? 5000 : 8000
  return Math.min(30000, Math.max(minimum, requested))
}

function displayTime(timestamp) {
  var date = new Date(Number(timestamp))
  if (isNaN(date.getTime())) return ""
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
}

if (typeof module !== "undefined") {
  module.exports = {
    asString: asString,
    iconSource: iconSource,
    snapshotOf: snapshotOf,
    durationFor: durationFor,
    displayTime: displayTime
  }
}
