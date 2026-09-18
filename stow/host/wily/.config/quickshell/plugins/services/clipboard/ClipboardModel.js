// Newest first; a repeat replaces its older entry at the top.
function add(history, text, at, limit) {
  if (text.length === 0) return history
  return [{ text: text, at: at }]
    .concat(history.filter(function(entry) { return entry.text !== text }))
    .slice(0, limit)
}

function removeAt(history, index) {
  var next = Array.isArray(history) ? history.slice() : []
  if (index < 0 || index >= next.length) return next
  next.splice(index, 1)
  return next
}

// One line, bounded so a huge copy does not lay out a huge Text.
function preview(text) {
  return text.slice(0, 500).replace(/\s+/g, " ").trim()
}
