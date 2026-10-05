// The selectable row steps rows away from current, backward when negative,
// wrapping; separators and disabled rows are skipped. From no row (-1), one
// step lands on the first or the last.
function step(rows, current, steps) {
  const count = rows.length;
  const forward = steps > 0;
  let index = current;
  for (let moved = 0; moved < Math.abs(steps); moved++) {
    let next = -1;
    for (let i = 1; i <= count && next < 0; i++) {
      const candidate =
        ((index < 0 && !forward ? 0 : index) + (forward ? i : -i) + count) %
        count;
      if (!rows[candidate].isSeparator && rows[candidate].enabled !== false)
        next = candidate;
    }
    if (next < 0) return -1;
    index = next;
  }
  return index;
}

// Hyphens and case are ignored, so "wifi" finds "Wi-Fi".
function matches(row, query) {
  const searchable = (text) =>
    String(text || "")
      .toLowerCase()
      .replace(/-/g, "");
  return searchable(row.text).indexOf(searchable(query)) >= 0;
}

// Launcher rows are rebuilt on every change and match by key; tray entries by identity.
function sameRow(a, b) {
  return a === b || (!!b && a.key !== undefined && a.key === b.key);
}

function clamp(value, low, high) {
  return Math.max(low, Math.min(value, high));
}

// Card position in an area starting at the bar's bottom edge. A below anchor is
// a bar button, any other anchor is the row whose submenu this is; no anchor centers.
function place(anchor, width, height, screenWidth, screenHeight) {
  const margin = 8;
  const maxX = screenWidth - width - margin;
  const maxY = screenHeight - height - margin;
  if (!anchor)
    return {
      x: Math.round((screenWidth - width) / 2),
      y: clamp(Math.round((screenHeight - height) / 2), 0, maxY),
    };
  if (anchor.below) return { x: clamp(anchor.x, margin, maxX), y: 0 };
  const right = anchor.x + anchor.width + 2;
  return {
    x: clamp(
      right + width <= screenWidth - margin ? right : anchor.x - width - 2,
      margin,
      maxX,
    ),
    y: clamp(anchor.y - 6, 0, maxY),
  };
}
