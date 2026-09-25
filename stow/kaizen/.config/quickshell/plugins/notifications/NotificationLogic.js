
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

// Compiles host rules (host.notificationRules) matching `field: pattern` (app,
// summary, body); a rule with a bad pattern or no fields is dropped.
function compileRules(rules) {
  return (Array.isArray(rules) ? rules : []).map(function(rule) {
    var match = (rule && rule.match) || {}
    var fields = Object.keys(match)
    if (fields.length === 0) return null
    try {
      return {
        checks: fields.map(function(field) { return { field: field, pattern: new RegExp(match[field]) } }),
        critical: !!rule.critical,
        dedup: rule.dedup || null,
        icon: iconSource(rule.icon)
      }
    } catch (error) {
      console.warn("notifications: dropping rule " + JSON.stringify(rule) + ": " + error)
      return null
    }
  }).filter(Boolean)
}

// The rules whose every field matches; an unknown field matches as "".
function matchingRules(notification, rules) {
  var fields = { app: notification.appName, summary: notification.summary, body: notification.body }
  return (rules || []).filter(function(rule) {
    return rule.checks.every(function(check) { return check.pattern.test(asString(fields[check.field])) })
  })
}

// Raised to critical (2) by any matching critical rule.
function urgencyOf(notification, rules) {
  var critical = matchingRules(notification, rules).some(function(rule) { return rule.critical })
  return critical ? 2 : Number(notification.urgency)
}

// The `{ group, keep }` of the first matching rule with one, else null.
function dedupOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function(rule) { return rule.dedup })
  return rule ? rule.dedup : null
}

// The icon of the first matching rule with one, else "".
function iconOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function(rule) { return rule.icon })
  return rule ? rule.icon : ""
}

function snapshotOf(notification, timestamp, rules) {
  return {
    app: asString(notification.appName),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    icon: iconOf(notification, rules),
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
