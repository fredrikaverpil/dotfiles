var DAY_COUNT = 3;

function pad(number) {
  return (number < 10 ? "0" : "") + number;
}

function midnight(date, days) {
  return new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate() + (days || 0),
  );
}

// RFC3339 with the local offset, as events.list requires.
function stamp(date) {
  var offset = -date.getTimezoneOffset();
  var minutes = Math.abs(offset);
  return (
    date.getFullYear() +
    "-" +
    pad(date.getMonth() + 1) +
    "-" +
    pad(date.getDate()) +
    "T" +
    pad(date.getHours()) +
    ":" +
    pad(date.getMinutes()) +
    ":" +
    pad(date.getSeconds()) +
    (offset < 0 ? "-" : "+") +
    pad(Math.floor(minutes / 60)) +
    ":" +
    pad(minutes % 60)
  );
}

function listCommand(now) {
  return [
    "dcal",
    "--json",
    "ipc",
    "events.list",
    "from=" + stamp(midnight(now)),
    "to=" + stamp(midnight(now, DAY_COUNT)),
  ];
}

// dcal stores all-day dates as UTC midnight; they are local calendar dates.
function allDayDate(text) {
  var parts = String(text).slice(0, 10).split("-");
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
}

function clock(date) {
  return pad(date.getHours()) + ":" + pad(date.getMinutes());
}

// The config's `emoji`, each a JavaScript regex on the calendar name mapped to
// its emoji, in file order; a regex that does not compile is skipped with a
// warning.
function emojiPatterns(emojiByRegex) {
  if (!emojiByRegex || typeof emojiByRegex !== "object") return [];
  return Object.keys(emojiByRegex)
    .map(function (source) {
      try {
        return {
          pattern: new RegExp(source),
          emoji: String(emojiByRegex[source]),
        };
      } catch (error) {
        console.warn("calendar: skipping emoji " + source + ": " + error);
        return null;
      }
    })
    .filter(Boolean);
}

// Maps calendar id to the emoji of the first config regex matching its name,
// from a calendars.list reply.
function emojis(text, emojiByRegex) {
  var calendars;
  try {
    calendars = JSON.parse(text);
  } catch (error) {
    return {};
  }
  var result = {};
  if (!Array.isArray(calendars)) return result;
  var patterns = emojiPatterns(emojiByRegex);
  calendars.forEach(function (calendar) {
    if (!calendar) return;
    var match = patterns.find(function (entry) {
      return entry.pattern.test(String(calendar.name || ""));
    });
    result[calendar.id] = match ? match.emoji : "";
  });
  return result;
}

// Unreadable dates land on the first day with a "?" time rather than vanish.
function row(event, dayStart, dayEnd, emojiById, first) {
  var start = event.allDay ? allDayDate(event.start) : new Date(event.start);
  var end = event.allDay ? allDayDate(event.end) : new Date(event.end);
  var readable = !isNaN(start) && !isNaN(end);
  if (!readable && !first) return null;
  if (readable && (start >= dayEnd || (end <= dayStart && start < dayStart)))
    return null;
  var url = String(event.meetingUrl || "");
  return {
    uid: String(event.uid || ""),
    start: String(event.start || ""),
    emoji: (emojiById || {})[event.calendarId] || "",
    summary: String(event.summary || "") || "(no title)",
    location: String(event.location || ""),
    // Invites come from others; only web links reach xdg-open.
    meetingUrl: /^https:\/\//i.test(url) ? url : "",
    allDay: event.allDay === true,
    at: readable ? start.getTime() : 0,
    until: readable ? end.getTime() : 0,
    time: !readable
      ? "?"
      : event.allDay
        ? "all day"
        : (start >= dayStart ? clock(start) : "…") +
          "–" +
          (end <= dayEnd ? clock(end) : "…"),
  };
}

// Returns DAY_COUNT days from now's midnight, or null for anything but an events.list reply.
function parse(text, now, emojiById) {
  var events;
  try {
    events = JSON.parse(text).events;
  } catch (error) {
    return null;
  }
  if (!Array.isArray(events)) return null;

  var days = [];
  for (var index = 0; index < DAY_COUNT; index++) {
    var dayStart = midnight(now, index);
    var dayEnd = midnight(now, index + 1);
    var rows = events
      .filter(function (event) {
        return event && event.status !== "cancelled";
      })
      .map(function (event) {
        return row(event, dayStart, dayEnd, emojiById, index === 0);
      })
      .filter(function (entry) {
        return entry !== null;
      })
      .sort(function (a, b) {
        return (
          b.allDay - a.allDay ||
          a.at - b.at ||
          a.summary.localeCompare(b.summary)
        );
      });
    days.push({ date: dayStart, events: rows });
  }
  return days;
}
