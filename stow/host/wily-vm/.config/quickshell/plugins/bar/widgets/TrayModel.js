// Kept out of Tray.qml so it can be tested without a Quickshell engine.

// An app may set any of these and skip the rest.
function labelFor(item) {
  if (!item) return ""
  return String(item.title || item.tooltipTitle || item.id || "")
}

// Registration order is a startup race, so unsorted the icons land in a
// different slot on each boot.
function sortItems(items) {
  return [...items].sort((a, b) => String(a.id).localeCompare(String(b.id)))
}

// The icon theme name behind an `image://icon/NAME` url, or "" when the url is
// not a plain theme lookup and should be used as-is.
//
// A `?path=` query means the icon lives outside any theme, so the name alone
// would not resolve.
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
