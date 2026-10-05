function childrenOf(items, parent) {
  var entries = items || {};
  var prefix = parent === "root" ? "" : parent + ".";
  var depth = parent === "root" ? 1 : parent.split(".").length + 1;
  return Object.keys(entries).filter(function (id) {
    return id.indexOf(prefix) === 0 && id.split(".").length === depth;
  });
}

function descendantsOf(items, parent) {
  var entries = items || {};
  var prefix = parent === "root" ? "" : parent + ".";
  return Object.keys(entries).filter(function (id) {
    return id !== parent && id.indexOf(prefix) === 0;
  });
}

function pathFrom(items, id, level) {
  var parts = id.split(".").slice(0, -1);
  var skip = level === "root" ? 0 : level.split(".").length;
  return parts
    .slice(skip)
    .map(function (part, index) {
      return items[parts.slice(0, skip + index + 1).join(".")].label;
    })
    .join(" › ");
}

function rowFor(items, id, level) {
  var child = items[id];
  return {
    id: id,
    label: child.label,
    icon: child.icon,
    detail: pathFrom(items, id, level),
    enabled: child.enabled !== false,
    entry: null,
    action: child.action || null,
    submenu: child.provider !== undefined || childrenOf(items, id).length > 0,
  };
}

// Apps carry their own identity (entry.id); everything else launched from the
// static tree is keyed by its menu id. Rows never carry a count field of
// their own, so this stays a pure lookup rather than shaping the row.
function frecency(row, counts) {
  var id = row.entry ? row.entry.id : row.id;
  return (counts || {})[id] || 0;
}

// Frecency only reorders items that have actually been launched: unlaunched
// rows tie at zero and fall back to whatever order they were already in.
function byFrecency(counts) {
  return function (a, b) {
    return frecency(b, counts) - frecency(a, counts);
  };
}

// Hyphens are ignored, so "wifi" finds "Wi-Fi".
function searchable(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/-/g, "");
}

function matches(row, query) {
  var value = searchable(query);
  return (
    searchable(row.label).indexOf(value) >= 0 ||
    (row.chord !== undefined && searchable(row.chord).indexOf(value) >= 0)
  );
}

// Every provider is a function of the detail column, so an unknown name is an
// empty level rather than a dead menu.
function rowsFrom(providers, name, detail) {
  var source = (providers || {})[name];
  return source ? source(detail || "") : [];
}

function rowsFor(items, level, query, providers, counts) {
  var item = items[level];
  var normalizedQuery = String(query || "").toLowerCase();
  var filterMatches = function (row) {
    return matches(row, normalizedQuery);
  };

  if (item && item.provider !== undefined) {
    var rows = rowsFrom(providers, item.provider, "");
    return (
      normalizedQuery.length === 0 ? rows.slice() : rows.filter(filterMatches)
    ).sort(byFrecency(counts));
  }
  if (normalizedQuery.length === 0) {
    return childrenOf(items, level)
      .map(function (id) {
        return rowFor(items, id, level);
      })
      .sort(byFrecency(counts));
  }

  var found = descendantsOf(items, level).map(function (id) {
    return rowFor(items, id, level);
  });
  if (level === "root")
    found = found.concat(rowsFrom(providers, "apps", "Apps"));
  return found
    .filter(function (row) {
      return row.enabled && filterMatches(row);
    })
    .sort(function (a, b) {
      return (
        byFrecency(counts)(a, b) || (a.detail ? 1 : 0) - (b.detail ? 1 : 0)
      );
    });
}

function parentLevel(level) {
  if (level === "root") return "root";
  return level.indexOf(".") >= 0
    ? level.split(".").slice(0, -1).join(".")
    : "root";
}
