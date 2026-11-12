// Newest first; a repeat replaces its older entry at the top.
function add(history, text, at, limit) {
  if (text.length === 0) return history;
  return [{ text: text, at: at }]
    .concat(
      history.filter(function (entry) {
        return entry.text !== text;
      }),
    )
    .slice(0, limit);
}

function removeAt(history, index) {
  var next = Array.isArray(history) ? history.slice() : [];
  if (index < 0 || index >= next.length) return next;
  next.splice(index, 1);
  return next;
}

// The text's lines, without the blank ones at either end.
function lines(text) {
  var all = text.split("\n");
  while (all.length > 0 && all[0].trim() === "") all.shift();
  while (all.length > 0 && all[all.length - 1].trim() === "") all.pop();
  return all;
}

// The first non-blank line, bounded so a huge copy does not lay out a huge
// Text.
function preview(text) {
  var first = lines(text.slice(0, 2000))[0] || "";
  return first.slice(0, 500).replace(/\s+/g, " ").trim();
}

// How many lines follow the preview's.
function moreLines(text) {
  return Math.max(0, lines(text).length - 1);
}

var DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function pad(value) {
  return (value < 10 ? "0" : "") + value;
}

// "14:01" on now's day, "Wed 13:02" before it.
function stamp(at, now) {
  var time = pad(at.getHours()) + ":" + pad(at.getMinutes());
  return at.toDateString() === now.toDateString()
    ? time
    : DAYS[at.getDay()] + " " + time;
}
