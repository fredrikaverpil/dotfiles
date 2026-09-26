// Next selectable row from current, wrapping; separators are skipped.
function step(rows, current, forward) {
  const count = rows.length
  for (let i = 1; i <= count; i++) {
    const index = ((current < 0 && !forward ? 0 : current) + (forward ? i : -i) + count) % count
    if (!rows[index].isSeparator) return index
  }
  return -1
}

// Launcher rows are rebuilt on every change and match by key; tray entries by identity.
function sameRow(a, b) {
  return a === b || (!!b && a.key !== undefined && a.key === b.key)
}

function clamp(value, low, high) {
  return Math.max(low, Math.min(value, high))
}

// Card position in an area starting at the bar's bottom edge. A below anchor is
// a bar button, any other anchor is the row whose submenu this is; no anchor centers.
function place(anchor, width, height, screenWidth, screenHeight) {
  const margin = 8
  const maxX = screenWidth - width - margin
  const maxY = screenHeight - height - margin
  if (!anchor) return { x: Math.round((screenWidth - width) / 2), y: clamp(Math.round((screenHeight - height) / 2), 0, maxY) }
  if (anchor.below) return { x: clamp(anchor.x, margin, maxX), y: 0 }
  const right = anchor.x + anchor.width + 2
  return {
    x: clamp(right + width <= screenWidth - margin ? right : anchor.x - width - 2, margin, maxX),
    y: clamp(anchor.y - 6, 0, maxY),
  }
}
