// Newest first; a repeat replaces its older entry at the top.
function add(history, text, at, limit) {
  if (text.length === 0) return history
  return [{ text: text, at: at }]
    .concat(history.filter(function(entry) { return entry.text !== text }))
    .slice(0, limit)
}

// One line, bounded so a huge copy does not lay out a huge Text.
function preview(text) {
  return text.slice(0, 500).replace(/\s+/g, " ").trim()
}
