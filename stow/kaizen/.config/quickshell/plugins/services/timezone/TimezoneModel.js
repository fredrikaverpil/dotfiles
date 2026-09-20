// The shell reads the zone from timedated and the clock from date(1): Qt's JS
// engine has no Intl, and it silently ignores toLocaleString's timeZone option
// rather than failing, so every zone would render as the local one.

var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

// "Sun Oct 25 01:00:00 2026 UT = Sun Oct 25 02:00:00 2026 CET isdst=0 gmtoff=3600"
var DUMP = new RegExp(
  "^\\S+\\s+\\w{3} (\\w{3}) +(\\d{1,2}) (\\d{2}):(\\d{2}):(\\d{2}) (\\d{4}) UT" +
  " = (\\w{3}) (\\w{3}) +(\\d{1,2}) (\\d{2}):(\\d{2}):(\\d{2}) (\\d{4}) (\\S+)" +
  " isdst=(\\d+) gmtoff=(-?\\d+)")

function offsetLabel(seconds) {
  if (!isFinite(seconds)) return ""
  var sign = seconds < 0 ? "-" : "+"
  var total = Math.abs(Math.round(seconds / 60))
  return "UTC" + sign + pad(Math.floor(total / 60)) + ":" + pad(total % 60)
}

function pad(number) {
  return (number < 10 ? "0" : "") + number
}

// zdump prints a change as two lines: the last second of the old offset and
// the first of the new. Only the second describes the change, and the pair is
// always exactly one second apart. Lines outside the requested years carry
// unparseable sentinel dates and drop out here.
function transitions(text) {
  var found = []
  String(text || "").split("\n").forEach(function (line) {
    var match = DUMP.exec(line)
    if (!match) return
    var month = MONTHS.indexOf(match[1])
    if (month < 0) return
    found.push({
      at: Date.UTC(Number(match[6]), month, Number(match[2]),
        Number(match[3]), Number(match[4]), Number(match[5])),
      local: match[7] + " " + Number(match[9]) + " " + match[8] + " " + match[13]
        + ", " + match[10] + ":" + match[11],
      abbreviation: match[14],
      dst: match[15] !== "0",
      offset: Number(match[16]),
    })
  })
  return found.filter(function (entry, index) {
    var next = found[index + 1]
    return !(next && next.at === entry.at + 1000)
  })
}

// The zone's state now is whatever the most recent change left behind, and the
// next change is the first still ahead. A zone with no changes in range simply
// does not observe DST.
function dstFor(list, nowMs) {
  var now = isFinite(nowMs) ? nowMs : Date.now()
  var past = list.filter(function (entry) { return entry.at <= now })
  var ahead = list.filter(function (entry) { return entry.at > now })
  return {
    observed: list.length > 0,
    inEffect: past.length > 0 && past[past.length - 1].dst,
    next: ahead.length > 0 ? ahead[0] : null,
  }
}

// Tagged lines from one shell call; an absent or short line leaves its fields
// empty rather than rendering "undefined" into the panel.
function parse(text, nowMs) {
  var result = {
    zone: "", synchronized: false, time: "", date: "", weekday: "",
    offset: "", abbreviation: "", utcTime: "", utcDate: "",
    dst: { observed: false, inEffect: false, next: null },
  }
  var dump = []

  String(text || "").split("\n").forEach(function (line) {
    var parts = line.split("|")
    if (parts[0] === "zone") result.zone = parts[1] || ""
    else if (parts[0] === "ntp") result.synchronized = parts[1] === "yes"
    else if (parts[0] === "clock" && parts.length >= 6) {
      result.time = parts[1]
      result.date = parts[2]
      result.weekday = parts[3]
      result.offset = parts[4]
      result.abbreviation = parts[5]
    } else if (parts[0] === "utc" && parts.length >= 3) {
      result.utcTime = parts[1]
      result.utcDate = parts[2]
    } else if (parts[0] === "dump") dump.push(line.slice(5))
  })

  result.dst = dstFor(transitions(dump.join("\n")), nowMs)
  return result
}

// date(1) prints +0900. Seconds, so the panel can compare it with what the
// shell's own engine believes and spot a zone change it has not picked up.
function offsetSeconds(offset) {
  var match = /^([+-])(\d{2})(\d{2})$/.exec(String(offset || ""))
  if (!match) return null
  var value = Number(match[2]) * 3600 + Number(match[3]) * 60
  return match[1] === "-" ? -value : value
}

// Qt resolves the zone once at startup, so after a change the bar clock can
// still be on the old one while date(1) reports the new.
function staleClock(offset, engineMinutes) {
  var actual = offsetSeconds(offset)
  if (actual === null || !isFinite(engineMinutes)) return false
  return actual !== -engineMinutes * 60
}

// An abbreviation is only worth showing when it is not the offset repeated:
// zones without a name print "+0545" for both.
function abbreviationLabel(abbreviation, offset) {
  var text = String(abbreviation || "")
  return text === String(offset || "") ? "" : text
}

function dstLabel(dst) {
  if (!dst || !dst.observed) return "Not observed"
  return dst.inEffect ? "In effect" : "Standard time"
}

function nextLabel(dst) {
  if (!dst || !dst.next) return "No further changes"
  return dst.next.local + " → " + dst.next.abbreviation
    + " (" + offsetLabel(dst.next.offset) + ")"
}
