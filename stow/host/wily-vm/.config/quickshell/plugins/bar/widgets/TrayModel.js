// String handling for the tray, kept out of Tray.qml so it can be tested
// without a Quickshell engine. See tests/README.md for that boundary.

// What a row is called. An app may set any of these and skip the rest.
function labelFor(item) {
  if (!item) return ""
  return String(item.title || item.tooltipTitle || item.id || "")
}

// Registration order is a startup race between apps, so an unsorted tray puts
// a given icon in a different slot on each boot and muscle memory never forms.
function sortItems(items) {
  return [...items].sort((a, b) => String(a.id).localeCompare(String(b.id)))
}

// The icon theme name behind an `image://icon/NAME` url, or "" when the url is
// not a plain theme lookup and should be used as-is.
//
// A `?path=` query means the app ships its icon outside any theme and
// Quickshell searches that directory, so the name alone would not resolve and
// must not be second-guessed. Anything else -- a file:// url, an absolute path,
// a pixmap the app sent over the bus -- is likewise not a theme lookup.
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
