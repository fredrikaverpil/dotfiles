
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

// The source of a Google Calendar reminder, else "".
// Slack relays them "from Google Calendar"; Chromium prefixes the body with the origin.
function calendarReminder(notification) {
  var app = asString(notification.appName)
  if (app === "Slack" && / from Google Calendar$/.test(asString(notification.summary))) return "slack"
  if (app === "Chromium" && /^calendar\.google\.com\n/.test(asString(notification.body))) return "chromium"
  return ""
}

// Compiles host rules of `field: pattern` (app, summary, body); a rule with a bad
// pattern or no fields is dropped.
function criticalRules(rules) {
  return (Array.isArray(rules) ? rules : []).map(function(rule) {
    var fields = Object.keys(rule || {})
    if (fields.length === 0) return null
    try {
      return fields.map(function(field) { return { field: field, pattern: new RegExp(rule[field]) } })
    } catch (error) {
      console.warn("notifications: dropping critical rule " + JSON.stringify(rule) + ": " + error)
      return null
    }
  }).filter(Boolean)
}

// Whether every field of some rule matches; an unknown field matches as "".
function matchesRule(notification, rules) {
  var fields = { app: notification.appName, summary: notification.summary, body: notification.body }
  return (rules || []).some(function(rule) {
    return rule.every(function(check) { return check.pattern.test(asString(fields[check.field])) })
  })
}

// Google Calendar reminders and rule matches are raised to critical (2).
function urgencyOf(notification, rules) {
  return calendarReminder(notification) || matchesRule(notification, rules) ? 2 : Number(notification.urgency)
}

function snapshotOf(notification, timestamp, rules) {
  return {
    app: asString(notification.appName),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    urgency: urgencyOf(notification, rules),
    timestamp: timestamp === undefined ? Date.now() : timestamp
  }
}

function durationFor(notification, lowUrgency, criticalUrgency, rules) {
  var urgency = urgencyOf(notification, rules)
  if (urgency === criticalUrgency || notification.resident) return 0

  // Zero is the spec's "never expire"; negative or unparseable means server default.
  var requested = Number(notification.expireTimeout)
  if (requested === 0) return 0
  if (!isFinite(requested) || requested < 0) requested = 0

  var minimum = urgency === lowUrgency ? 5000 : 8000
  return Math.min(30000, Math.max(minimum, requested))
}

// Replaces known `:shortcode:`s; unknown ones (custom Slack emoji) stay as text.
function emojify(text, shortcodes) {
  return text.replace(/:([\w+-]+):/g, function(match, name) {
    return Object.prototype.hasOwnProperty.call(shortcodes, name) ? shortcodes[name] : match
  })
}

// "default" is the body click, not a button.
function buttons(actions) {
  return Array.prototype.filter.call(actions || [], function(action) { return action.identifier !== "default" })
}
