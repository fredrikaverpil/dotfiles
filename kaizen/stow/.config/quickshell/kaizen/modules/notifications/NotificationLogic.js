.import "../../Ui/Jsonc.js" as Jsonc

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

// An image the app gave as a path loads as a file: the icon provider answers a
// missing file with a placeholder, a file source with an error.
function imageSource(image) {
  var prefix = "image://icon/";
  var value = asString(image);
  return value.indexOf(prefix + "/") === 0
    ? "file://" + value.substring(prefix.length)
    : value;
}

function isString(value) {
  return typeof value === "string" ? "" : "not a string";
}

function isBool(value) {
  return typeof value === "boolean" ? "" : "not a boolean";
}

function oneOf(values) {
  return function (value) {
    return values.indexOf(value) >= 0 ? "" : "not one of " + values.join(", ");
  };
}

// An object holding only `fields`, each checked unless null or absent; the
// `required` ones must be set.
function record(fields, required) {
  return function (value) {
    if (!value || typeof value !== "object" || Array.isArray(value))
      return "not an object";
    var missing = (required || []).find(function (name) {
      return value[name] === undefined || value[name] === null;
    });
    if (missing) return missing + ": missing";
    for (var name in value) {
      if (!Object.prototype.hasOwnProperty.call(fields, name))
        return name + ": unknown field";
      if (value[name] === undefined || value[name] === null) continue;
      var error = fields[name](value[name]);
      if (error) return name + ": " + error;
    }
    return "";
  };
}

function listOf(check) {
  return function (value) {
    if (!Array.isArray(value)) return "not a list";
    for (var i = 0; i < value.length; i++) {
      var error = check(value[i]);
      if (error) return "[" + i + "]: " + error;
    }
    return "";
  };
}

function stringMap(value) {
  if (!value || typeof value !== "object" || Array.isArray(value))
    return "not an object";
  for (var name in value) {
    if (typeof value[name] !== "string") return name + ": not a string";
  }
  return "";
}

var paletteRoles = ["rose", "leaf", "wood", "water", "blossom", "sky"];

// A notification rule, as the rules files hold it. Every field but `match` is
// optional; null is unset.
var ruleCheck = record(
  {
    // JavaScript regexes keyed by notification field; the rule applies when
    // all match.
    match: record({ app: isString, summary: isString, body: isString }),
    // Urgency in place of the one the app sent; critical sticks, low expires
    // sooner. The first matching rule with one applies.
    urgency: oneOf(["low", "normal", "critical"]),
    // Palette colour of the border, on the toast and in the history, in place
    // of the one its urgency gives.
    border: oneOf(paletteRoles),
    // Animation of the border, on the toast and in the history: `orbit` keeps
    // a dash travelling around it, and dims the border itself so the dash
    // stands out; `heartbeat` thickens it in two soft beats, then rests; `glow`
    // breathes a halo around it, over the bar, the history panel and other
    // notifications.
    borderAnimation: oneOf(["orbit", "heartbeat", "glow"]),
    // Shows one copy of an event reported by several apps: `group` names the
    // event; the `keep` copy shows and dismisses the group's others, which are
    // held briefly in case it arrives.
    dedup: record({ group: isString, keep: isBool }, ["group"]),
    // Shows a burst of this rule's toasts as one: each is held briefly, then
    // the latest replaces the others and the one on screen, showing `summary`
    // and `body` in place of its own. A lone toast keeps the app's text.
    collapse: record({ summary: isString, body: isString }),
    // JavaScript regex of the app id of the window to focus when the
    // notification is activated, in place of the notification's own app.
    focus: isString,
    // Icon in place of the notification's, such as the sender an app relays
    // for; the notification's own moves to a badge on its corner unless
    // `badgeIcon` is set. A relative path resolves against the rules file's
    // directory.
    icon: isString,
    // Icon on the corner badge, resolved as `icon`. With `icon` set too, each
    // shows as set; otherwise the notification's own stays the icon, and the
    // badge icon takes its place when that cannot be loaded.
    badgeIcon: isString,
    // Emoji on the icon's corner badge, in Noto Color Emoji, in place of the
    // notification's own icon when `icon` moves it there.
    badgeEmoji: isString,
    // Buttons after the toast's own; pressing one runs `command` (program and
    // arguments, detached and not in a shell) under `env` plus
    // NOTIFICATION_APP, NOTIFICATION_SUMMARY and NOTIFICATION_BODY, and
    // dismisses the toast. They also show on the notification in the history,
    // where pressing one keeps the notification and closes the panel. The
    // first matching rule with any applies.
    actions: listOf(
      record(
        { label: isString, command: listOf(isString), env: stringMap },
        ["label", "command"],
      ),
    ),
  },
  ["match"],
);

// Why the rule is invalid, or "" when it is valid.
function ruleError(rule) {
  var error = ruleCheck(rule);
  if (error) return error;
  if (Object.keys(rule.match).length === 0) return "match: no fields";
  return "";
}

// The path to a rule's icon: a relative one resolves against `dir`.
function rulePath(path, dir) {
  var value = asString(path);
  if (!value || !dir || value.charAt(0) === "/" || value.indexOf("://") >= 0)
    return value;
  return dir + "/" + value;
}

// Compiles the rules of `file` (for messages and relative icons), matching
// `field: pattern`; an invalid rule is dropped with a warning.
function compileRules(rules, file) {
  var source = file ? file + ": " : "";
  var dir = file ? file.substring(0, file.lastIndexOf("/")) : "";
  if (!Array.isArray(rules)) {
    console.warn("notifications: " + source + "dropping rules: not a list");
    return [];
  }
  return rules
    .map(function (rule, index) {
      var error = ruleError(rule);
      try {
        if (error) throw error;
        var match = rule.match;
        return {
          checks: Object.keys(match).map(function (field) {
            return { field: field, pattern: new RegExp(match[field]) };
          }),
          urgency: rule.urgency || "",
          dedup: rule.dedup || null,
          collapse: rule.collapse || null,
          focus: rule.focus || "",
          icon: iconSource(rulePath(rule.icon, dir)),
          badgeIcon: iconSource(rulePath(rule.badgeIcon, dir)),
          badgeEmoji: rule.badgeEmoji || "",
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
          "notifications: " + source + "dropping rule " + index + " " +
            JSON.stringify(rule) + ": " + error,
        );
        return null;
      }
    })
    .filter(Boolean);
}

// The rules of every `{ path, text }` rules file, in file-name order whatever
// its directory: each holds a JSONC list of rules. A file that does not parse
// is skipped with a warning.
function rulesFrom(files) {
  function name(file) {
    return file.path.slice(file.path.lastIndexOf("/") + 1);
  }
  return files
    .slice()
    .sort(function (a, b) {
      return name(a) < name(b) ? -1 : name(a) > name(b) ? 1 : 0;
    })
    .reduce(function (rules, file) {
    var parsed;
    try {
      parsed = Jsonc.parse(file.text);
    } catch (error) {
      console.warn("notifications: " + file.path + ": skipping: " + error);
      return rules;
    }
    return rules.concat(compileRules(parsed, file.path));
  }, []);
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

// The badge icon of the first matching rule with one, else "".
function badgeIconOf(notification, rules) {
  var rule = matchingRules(notification, rules).find(function (rule) {
    return rule.badgeIcon;
  });
  return rule ? rule.badgeIcon : "";
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
    badgeIcon: badgeIconOf(notification, rules),
    badgeEmoji: ruleValue(notification, rules, "badgeEmoji"),
    border: ruleValue(notification, rules, "border"),
    borderAnimation: ruleValue(notification, rules, "borderAnimation"),
    // A rule's; the app's are on the live notification.
    actions: actionsOf(notification, rules),
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

// The glow's strength, 0 to 1, at `ms` into its 3200 ms breath.
function glow(ms) {
  return 0.5 - 0.5 * Math.cos(((ms % 3200) / 3200) * 2 * Math.PI);
}

// The glow's arrival flare, 1 on arrival easing out to 0 over 1500 ms.
function glowFlare(age) {
  if (!(age >= 0) || age >= 1500) return 0;
  var x = 1 - age / 1500;
  return x * x * x;
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
