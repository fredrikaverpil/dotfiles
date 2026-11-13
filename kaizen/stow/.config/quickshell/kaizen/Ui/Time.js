.pragma library

var DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function pad(value) {
  return (value < 10 ? "0" : "") + value;
}

// When something happened, as every panel shows it: "14:01" on now's day,
// "Wed 13:02" before it.
function stamp(at, now) {
  var time = pad(at.getHours()) + ":" + pad(at.getMinutes());
  return at.toDateString() === now.toDateString()
    ? time
    : DAYS[at.getDay()] + " " + time;
}
