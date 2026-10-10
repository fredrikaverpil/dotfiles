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

// A static tree's level at path, the keys of the submenus drilled into, and
// those submenus' names. A key no longer in the tree ends the walk.
function level(tree, path) {
  let rows = tree;
  const names = [];
  for (const key of path) {
    const row = rows.find((row) => row.key === key);
    if (!row) return { rows: [], names: names };
    rows = row.children;
    names.push(row.text);
  }
  return { rows: rows, names: names };
}

// One tree from the scopes around the focus, { title, rows } nearest first:
// their rows nearest first, a separator between scopes, and a row whose key a
// nearer scope has dropped. names are the titles outermost first.
function scoped(scopes) {
  const seen = new Set();
  let rows = [];
  for (const scope of scopes) {
    const own = scope.rows.filter(
      (row) => row.isSeparator || !seen.has(row.key),
    );
    if (!own.length) continue;
    own.forEach((row) => seen.add(row.key));
    rows = rows.concat(
      rows.length ? [{ isSeparator: true, enabled: true }] : [],
      own,
    );
  }
  const names = scopes
    .map((scope) => scope.title)
    .filter(Boolean)
    .reverse();
  return { rows: rows, names: names };
}

// A static tree's rows matching query, by text or keys: direct rows first,
// then deeper ones in the tree's order, with their path as the detail. trail
// holds the keys of the submenus between the level and the row. A row with
// adds stands for what was typed, at its own level only: a disabled hint
// without a query, else Add "query" with the query as its arg, unless a row
// beside it is named that.
function search(rows, query) {
  const typed = String(query || "").trim();
  if (!typed)
    return rows.map((row) =>
      row.adds ? Object.assign({}, row, { enabled: false }) : row,
    );
  const found = [];
  const visit = (rows, names, keys) => {
    for (const row of rows) {
      if (row.isSeparator || row.enabled === false || row.adds) continue;
      if (
        matches(row, typed) ||
        matches({ text: (row.keys || []).join("+") }, typed)
      )
        found.push(
          Object.assign({}, row, {
            detail: names.length ? names.join(" › ") : row.detail,
            trail: keys,
          }),
        );
      if (row.children)
        visit(row.children, names.concat([row.text]), keys.concat([row.key]));
    }
  };
  visit(rows, [], []);
  const named = rows.some(
    (row) =>
      !row.adds && String(row.text || "").toLowerCase() === typed.toLowerCase(),
  );
  const added = named
    ? []
    : rows
        .filter((row) => row.adds)
        .map((row) =>
          Object.assign({}, row, {
            text: 'Add "' + typed + '"',
            arg: typed,
            trail: [],
          }),
        );
  return found
    .filter((row) => !row.trail.length)
    .concat(
      found.filter((row) => row.trail.length),
      added,
    );
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

// Card position below-right of anchor, a rect in an area (a pointer has no
// size): flipped above or to the left of it where it does not fit, then kept
// 8 px inside. above says which side it took.
function hang(anchor, width, height, areaWidth, areaHeight) {
  const margin = 8;
  const below = anchor.y + anchor.height;
  const x =
    anchor.x + width <= areaWidth - margin
      ? anchor.x
      : anchor.x + anchor.width - width;
  const above = below + height > areaHeight - margin;
  return {
    x: clamp(x, margin, areaWidth - width - margin),
    y: clamp(
      above ? anchor.y - height : below,
      margin,
      areaHeight - height - margin,
    ),
    above: above,
  };
}
