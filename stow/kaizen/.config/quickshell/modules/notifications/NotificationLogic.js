function asString(value) {
  return value === undefined || value === null ? "" : String(value);
}

function iconSource(icon) {
  var value = asString(icon);
  if (!value) return "";
  if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0)
    return value;
  if (value.charAt(0) === "/") return "file://" + value;
  return value;
}

// Compiles host rules (host.notificationRules) matching `field: pattern` (app,
// summary, body); a rule with a bad pattern or no fields is dropped.
function compileRules(rules) {
  return (Array.isArray(rules) ? rules : [])
    .map(function (rule) {
      var match = (rule && rule.match) || {};
      var fields = Object.keys(match);
      if (fields.length === 0) return null;
      try {
        return {
          checks: fields.map(function (field) {
            return { field: field, pattern: new RegExp(match[field]) };
          }),
          urgency: rule.urgency || "",
          dedup: rule.dedup || null,
          collapse: rule.collapse || null,
          focus: rule.focus || "",
          icon: iconSource(rule.icon),
          badge: rule.badge || "",
          border: rule.border || "",
          borderAnimation: rule.borderAnimation || "",
          // Shaped as buttons, like the app's actions.
          actions: (rule.actions || []).map(function (action) {
            return {
              text: action.label,
              command: action.command,
              env: action.env || {},
            };
          }),
        };
      } catch (error) {
        console.warn(
          "notifications: dropping rule " + JSON.stringify(rule) + ": " + error,
        );
        return null;
      }
    })
    .filter(Boolean);
}

// The rules whose every field matches; an unknown field matches as "".
function matchingRules(notification, rules) {
  var fields = {
    app: notification.appName,
    summary: notification.summary,
    body: notification.body,
  };
  return (rules || []).filter(function (rule) {
    return rule.checks.every(function (check) {
      return check.pattern.test(asString(fields[check.field]));
    });
  });
}

var urgencies = { low: 0, normal: 1, critical: 2 };

// The urgency of the first matching rule with one, else the notification's own.
function urgencyOf(notification, rules) {
  var level = urgencies[ruleValue(notification, rules, "urgency")];
  return level === undefined ? Number(notification.urgency) : level;
}

// The `{ group, keep }` of the first matching rule with one, else null.
function dedupOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule.dedup;
  });
  return rule ? rule.dedup : null;
}

// The icon of the first matching rule with one, else "".
function iconOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule.icon;
  });
  return rule ? rule.icon : "";
}

// The actions of the first matching rule with any, else [].
function actionsOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule.actions.length;
  });
  return rule ? rule.actions : [];
}

// A rule action's command, under `env` with the notification's fields and the
// action's variables: execDetached's context form fails to convert on Qt 6.11.
function commandOf(record, action) {
  var env = Object.assign(
    {
      NOTIFICATION_APP: record.app,
      NOTIFICATION_SUMMARY: record.summary,
      NOTIFICATION_BODY: record.body,
    },
    action.env,
  );
  return ["env"].concat(
    Object.keys(env).map(function (name) {
      return name + "=" + asString(env[name]);
    }),
    action.command,
  );
}

// The `field` of the first matching rule with one, else "".
function ruleValue(notification, rules, field) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule[field];
  });
  return rule ? rule[field] : "";
}

// The window app id an app's notifications most likely belong to.
function appIdOf(notification) {
  return (
    asString(notification.desktopEntry).replace(/\.desktop$/, "") ||
    asString(notification.appName)
  );
}

// The app id pattern of the window to focus: the first matching rule's `focus`,
// else the notification's own app.
function focusPatternOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule.focus;
  });
  if (rule) return rule.focus;
  var appId = appIdOf(notification);
  return appId
    ? "(?i)^" + appId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$"
    : "";
}

function snapshotOf(notification, timestamp, rules) {
  return {
    app: asString(notification.appName),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    icon: iconOf(notification, rules),
    badge: ruleValue(notification, rules, "badge"),
    border: ruleValue(notification, rules, "border"),
    borderAnimation: ruleValue(notification, rules, "borderAnimation"),
    urgency: urgencyOf(notification, rules),
    timestamp: timestamp === undefined ? Date.now() : timestamp,
  };
}

// The heartbeat border's strength, 0 to 1, at `ms` into its 2400 ms cycle: a
// beat, a softer one 300 ms later, then rest.
function heartbeat(ms) {
  var t = ms % 2400;
  function beat(at, strength) {
    var x = (t - at) / 70;
    return strength * Math.exp(-x * x);
  }
  return beat(150, 1) + beat(450, 0.6);
}

function durationFor(notification, lowUrgency, criticalUrgency, rules) {
  var urgency = urgencyOf(notification, rules);
  if (urgency === criticalUrgency || notification.resident) return 0;

  // Zero is the spec's "never expire"; negative or unparseable means server default.
  var requested = Number(notification.expireTimeout);
  if (requested === 0) return 0;
  if (!isFinite(requested) || requested < 0) requested = 0;

  var minimum = urgency === lowUrgency ? 5000 : 8000;
  return Math.min(30000, Math.max(minimum, requested));
}

// Shortcode -> emoji, from the session's `[{ emoji, shortcodes }]`.
function shortcodesFrom(emoji) {
  var codes = {};
  emoji.forEach(function (entry) {
    entry.shortcodes.forEach(function (name) {
      codes[name] = entry.emoji;
    });
  });
  return codes;
}

// Replaces known `:shortcode:`s; unknown ones (custom Slack emoji) stay as text.
function emojify(text, shortcodes) {
  return text.replace(/:([\w+-]+):/g, function (match, name) {
    return Object.prototype.hasOwnProperty.call(shortcodes, name)
      ? shortcodes[name]
      : match;
  });
}

// "default" is the body click, not a button. A rule's actions follow the app's.
function buttons(actions, ruleActions) {
  return Array.prototype.filter
    .call(actions || [], function (action) {
      return action.identifier !== "default";
    })
    .concat(ruleActions || []);
}

// Everything the app sent, unprocessed, for debugging what an app supports.
function captureOf(notification, timestamp) {
  var hints;
  try {
    hints = JSON.parse(JSON.stringify(notification.hints || {}));
  } catch (error) {
    hints = String(notification.hints);
  }
  return {
    timestamp: timestamp,
    id: notification.id,
    app: asString(notification.appName),
    desktopEntry: asString(notification.desktopEntry),
    appIcon: asString(notification.appIcon),
    summary: asString(notification.summary),
    body: asString(notification.body),
    image: asString(notification.image),
    urgency: Number(notification.urgency),
    expireTimeout: Number(notification.expireTimeout),
    resident: !!notification.resident,
    transient: !!notification.transient,
    actions: Array.prototype.map.call(
      notification.actions || [],
      function (action) {
        return { identifier: action.identifier, text: action.text };
      },
    ),
    hints: hints,
  };
}
