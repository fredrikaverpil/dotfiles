function labelFor(item) {
  if (!item) return "";
  return String(item.title || item.tooltipTitle || item.id || "");
}

function sortItems(items) {
  return [...items].sort((a, b) => String(a.id).localeCompare(String(b.id)));
}

// Whether count buttons fit in maxWidth.
function fits(count, maxWidth, slot, spacing) {
  return count === 0 || count * (slot + spacing) - spacing <= maxWidth;
}

function themeIconName(url) {
  const value = String(url || "");
  const prefix = "image://icon/";
  if (!value.startsWith(prefix)) return "";
  const query = value.indexOf("?");
  if (query >= 0 && value.indexOf("path=", query) >= 0) return "";
  return query >= 0
    ? value.slice(prefix.length, query)
    : value.slice(prefix.length);
}
