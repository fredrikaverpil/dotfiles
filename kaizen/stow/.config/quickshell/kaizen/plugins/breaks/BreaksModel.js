var MINUTE = 60 * 1000;

var DEFAULT_REMINDERS = [
  {
    id: "eyes",
    everyMinutes: 20,
    // MDI eye-outline.
    icon: "\u{F06D0}",
    title: "Look into the distance",
    details: ["20 s at something 6 m away"],
    seconds: 20,
  },
  {
    id: "move",
    everyMinutes: 30,
    // MDI run.
    icon: "\u{F070E}",
    title: "Stand up and move",
    details: [
      "10 squats",
      "Shoulder rolls",
      "Hip-flexor stretch",
      "Walk for 2 min",
    ],
    seconds: 0,
  },
];

// One entry of breaks.jsonc's reminders, or null when invalid.
function reminder(r) {
  if (!r || typeof r !== "object") return null;
  if (typeof r.id !== "string" || r.id === "") return null;
  if (typeof r.everyMinutes !== "number" || !(r.everyMinutes > 0)) return null;
  if (typeof r.title !== "string" || r.title === "") return null;
  var details = Array.isArray(r.details)
    ? r.details.filter(function (d) {
        return typeof d === "string" && d !== "";
      })
    : typeof r.detail === "string" && r.detail !== ""
      ? [r.detail]
      : [];
  return {
    id: r.id,
    everyMinutes: r.everyMinutes,
    // MDI coffee by default.
    icon: typeof r.icon === "string" && r.icon !== "" ? r.icon : "\u{F0176}",
    title: r.title,
    details: details,
    seconds: typeof r.seconds === "number" && r.seconds > 0 ? r.seconds : 0,
  };
}

// breaks.jsonc's settings. reminders, when set, replaces the defaults; an
// invalid entry, or one repeating an earlier id, is dropped.
function settings(config) {
  var c = config || {};
  var reminders = DEFAULT_REMINDERS;
  if (Array.isArray(c.reminders)) {
    var ids = {};
    reminders = [];
    for (var i = 0; i < c.reminders.length; i++) {
      var r = reminder(c.reminders[i]);
      if (r && !ids[r.id]) {
        ids[r.id] = true;
        reminders.push(r);
      }
    }
  }
  return {
    idleMinutes:
      typeof c.idleMinutes === "number" && c.idleMinutes > 0
        ? c.idleMinutes
        : 5,
    reminders: reminders,
  };
}

// "32m", "1h", "1h 5m": whole minutes, rounded down.
function duration(ms) {
  var total = Math.max(0, Math.floor(ms / MINUTE));
  var h = Math.floor(total / 60);
  var m = total % 60;
  if (h === 0) return m + "m";
  return m === 0 ? h + "h" : h + "h " + m + "m";
}

// How many reminders a session of this length has come due for.
function remindersDue(elapsedMs, intervalMs) {
  return Math.max(0, Math.floor(elapsedMs / intervalMs));
}

// The reminder with the longest interval, the first of equals; null for none.
function longest(reminders) {
  var best = null;
  for (var i = 0; i < reminders.length; i++)
    if (!best || reminders[i].everyMinutes > best.everyMinutes)
      best = reminders[i];
  return best;
}

// What to show: { reminder, shown }. Of the reminders due beyond their shown
// count (shown, by id), the longest interval's, or null; shown marks every one
// due as shown.
function pick(reminders, elapsedMs, shown) {
  var next = {};
  var pending = [];
  for (var i = 0; i < reminders.length; i++) {
    var r = reminders[i];
    var due = remindersDue(elapsedMs, r.everyMinutes * MINUTE);
    if (due > (shown[r.id] || 0)) pending.push(r);
    next[r.id] = Math.max(due, shown[r.id] || 0);
  }
  return { reminder: longest(pending), shown: next };
}

// The reminder's detail for its nth show, rotating; "" for none.
function detail(r, n) {
  return r.details.length > 0 ? r.details[n % r.details.length] : "";
}

// "paused", "idle" (no session), "held" (DnD holds a reminder back), "dnd"
// (DnD, nothing held), "due" (the longest-interval reminder came due) or
// "active". shown is pick's.
function state(paused, active, elapsedMs, reminders, dnd, shown) {
  if (paused) return "paused";
  if (!active) return "idle";
  if (dnd) return pick(reminders, elapsedMs, shown).reminder ? "held" : "dnd";
  var r = longest(reminders);
  return r && remindersDue(elapsedMs, r.everyMinutes * MINUTE) > 0
    ? "due"
    : "active";
}

// The bar indicator for a state: { icon, text, role }, role a palette key.
function indicator(st, elapsedMs) {
  switch (st) {
    case "paused":
      return { icon: "\u{F051E}", text: "", role: "off" };
    case "idle":
      return { icon: "\u{F051B}", text: "0m", role: "off" };
    case "due":
      return { icon: "\u{F0176}", text: duration(elapsedMs), role: "wood" };
    // MDI bell-off, as the notifications' bell under DnD.
    case "dnd":
      return { icon: "\u{F009B}", text: duration(elapsedMs), role: "off" };
    case "held":
      return { icon: "\u{F009B}", text: duration(elapsedMs), role: "wood" };
    default:
      return { icon: "\u{F051B}", text: duration(elapsedMs), role: "fg" };
  }
}

// The launcher's status row.
function status(st, elapsedMs) {
  if (st === "paused") return "Paused";
  if (st === "idle") return "No active session";
  return "Active for " + duration(elapsedMs);
}
