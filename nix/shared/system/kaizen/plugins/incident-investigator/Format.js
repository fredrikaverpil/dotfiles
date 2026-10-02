.pragma library

var icons = {
  draft: String.fromCodePoint(0xF03EB),
  running: String.fromCodePoint(0xF051F),
  done: String.fromCodePoint(0xF012C),
  failed: String.fromCodePoint(0xF0159),
  cancelled: String.fromCodePoint(0xF073A),
  alert: String.fromCodePoint(0xF009A),
  plus: String.fromCodePoint(0xF0415),
  play: String.fromCodePoint(0xF040A),
  stop: String.fromCodePoint(0xF04DB),
  refresh: String.fromCodePoint(0xF0450),
  trash: String.fromCodePoint(0xF01B4),
  terminal: String.fromCodePoint(0xF018D),
  copy: String.fromCodePoint(0xF018F),
  reply: String.fromCodePoint(0xF045A),
  chevron: String.fromCodePoint(0xF0140),
  send: String.fromCodePoint(0xF048A)
}

// What a run can use; the daemon rejects anything else.
var models = ["claude-sonnet-5-5", "claude-opus-5-5"]
var efforts = ["low", "medium", "high", "xhigh", "max"]

// An investigation's name: its report's title, else its trace id, else when it started.
function name(item) {
  if (item.title || item.traceId) return item.title || item.traceId
  return item.startedAt ? Qt.formatDateTime(new Date(item.startedAt), "yyyy-MM-dd HH:mm") : "New investigation"
}

// Whether an investigation's names, notes, alert or conversation contain query, ignoring case.
function matches(item, query) {
  if (!query) return true
  var texts = [item.title, item.traceId, item.projects.join(" "), item.notes, item.error]
  if (item.alert) texts.push(item.alert.summary, item.alert.body)
  item.messages.forEach(function(message) { texts.push(message.text, (message.commands || []).join("\n")) })
  return texts.join("\n").toLowerCase().indexOf(query.toLowerCase()) >= 0
}

function ago(timestamp) {
  var minutes = Math.round((Date.now() - timestamp) / 60000)
  if (minutes < 1) return "just now"
  if (minutes < 60) return minutes + "m ago"
  if (minutes < 1440) return Math.round(minutes / 60) + "h ago"
  return Math.round(minutes / 1440) + "d ago"
}

function duration(ms) {
  var seconds = Math.round(ms / 1000)
  return seconds < 60 ? seconds + "s" : Math.floor(seconds / 60) + "m " + (seconds % 60) + "s"
}

// Splits markdown into its heading lines, its fenced code and the text between
// them, so a heading can be drawn at the body's size in its own colour, and code
// in the body's font.
function blocks(markdown) {
  var result = []
  var body = []
  var code = []
  // The open fence's marker, or "" outside one.
  var fence = ""
  function flush() {
    if (body.join("").trim()) result.push({ heading: false, code: false, text: body.join("\n") })
    body = []
  }
  markdown.split("\n").forEach(function(line) {
    if (fence) {
      if (line.trim().indexOf(fence) === 0) {
        result.push({ heading: false, code: true, text: code.join("\n") })
        code = []
        fence = ""
      } else {
        code.push(line)
      }
      return
    }
    var open = /^[ \t]*(```|~~~)/.exec(line)
    var heading = /^#{1,6}[ \t]+(.+?)[ \t]*#*[ \t]*$/.exec(line)
    if (open) {
      flush()
      fence = open[1]
    } else if (heading) {
      flush()
      result.push({ heading: true, code: false, text: heading[1] })
    } else {
      body.push(line)
    }
  })
  flush()
  // An unclosed fence runs to the end.
  if (fence) result.push({ heading: false, code: true, text: code.join("\n") })
  return result
}

// Turns markdown's inline code and bare URLs into coloured text in the body's font:
// Qt draws code spans in its own fixed font, larger than the body, and links in the
// application palette's blue, ignoring Text.linkColor.
// A [text](https://...) link is clickable and coloured; a bare URL is only coloured.
// ponytail: matches a run of backticks to the next equal run, without CommonMark's
// space stripping, and a link URL without parentheses; parse properly if spans
// render wrong.
function literals(markdown, color) {
  var pattern = /(`+)([\s\S]+?)\1(?!`)|\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)|https?:\/\/[^\s<>]*[^\s<>.,;:!?)'"]/g
  return markdown.replace(pattern, function(match, ticks, code, label, url) {
    // ASCII punctuation as entities, so markdown and HTML inside the span stay
    // literal, and a bare URL is not linked.
    var literal = (ticks ? code : label || match).replace(/[!-\/:-@\[-`{-~]/g, function(c) { return "&#" + c.charCodeAt(0) + ";" })
    var span = '<span style="color:' + color + '">' + literal + "</span>"
    return url ? '<a href="' + url.replace(/&/g, "&amp;").replace(/"/g, "&quot;") + '">' + span + "</a>" : span
  })
}
