
function labelFor(item) {
  if (!item) return ""
  return String(item.title || item.tooltipTitle || item.id || "")
}

function sortItems(items) {
  return [...items].sort((a, b) => String(a.id).localeCompare(String(b.id)))
}

function themeIconName(url) {
  const value = String(url || "")
  const prefix = "image://icon/"
  if (!value.startsWith(prefix)) return ""
  const query = value.indexOf("?")
  if (query >= 0 && value.indexOf("path=", query) >= 0) return ""
  return query >= 0 ? value.slice(prefix.length, query) : value.slice(prefix.length)
}

if (typeof module !== "undefined") {
  module.exports = { labelFor, sortItems, themeIconName }
}
