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

// Evolution sends normal-urgency meeting reminders. Keep them visible through
// unlock; desktopEntry is preferred and appName supports older notifications.
var criticalSenders = ["org.gnome.Evolution-alarm-notify", "evolution-alarm-notify"]

function isCriticalSender(notification) {
  if (criticalSenders.indexOf(asString(notification.desktopEntry)) >= 0) return true
  if (criticalSenders.indexOf(asString(notification.appName)) >= 0) return true
  return false
}

function urgencyFor(notification, criticalUrgency) {
  if (isCriticalSender(notification)) return criticalUrgency
  return Number(notification.urgency)
}

function snapshotOf(notification, timestamp, criticalUrgency) {
  return {
    app: asString(notification.appName),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    urgency: urgencyFor(notification, criticalUrgency),
    timestamp: timestamp === undefined ? Date.now() : timestamp
  }
}

function durationFor(notification, lowUrgency, criticalUrgency) {
  var urgency = urgencyFor(notification, criticalUrgency)
  if (urgency === criticalUrgency || notification.resident) return 0

  var requested = Number(notification.expireTimeout)
  if (!isFinite(requested) || requested <= 0) requested = 0

  var minimum = urgency === lowUrgency ? 5000 : 8000
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
    isCriticalSender: isCriticalSender,
    urgencyFor: urgencyFor,
    durationFor: durationFor,
    displayTime: displayTime
  }
}
