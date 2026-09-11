function parseBinds(raw) {
  return String(raw || "").trim().split("\n")
    .filter(function(line) { return line.length > 0 })
    .map(function(line) {
      var columns = line.split("\t")
      return { chord: columns[0], label: columns[1] || "", enabled: true }
    })
}

function childrenOf(items, parent) {
  var entries = items || {}
  var prefix = parent === "root" ? "" : parent + "."
  var depth = parent === "root" ? 1 : parent.split(".").length + 1
  return Object.keys(entries).filter(function(id) {
    return id.indexOf(prefix) === 0 && id.split(".").length === depth
  })
}

function descendantsOf(items, parent) {
  var entries = items || {}
  var prefix = parent === "root" ? "" : parent + "."
  return Object.keys(entries).filter(function(id) {
    return id !== parent && id.indexOf(prefix) === 0
  })
}

function pathFrom(items, id, level) {
  var parts = id.split(".").slice(0, -1)
  var skip = level === "root" ? 0 : level.split(".").length
  return parts.slice(skip).map(function(part, index) {
    return items[parts.slice(0, skip + index + 1).join(".")].label
  }).join(" › ")
}

function rowFor(items, id, level) {
  var child = items[id]
  return {
    id: id,
    label: child.label,
    icon: child.icon,
    detail: pathFrom(items, id, level),
    enabled: child.enabled !== false,
    entry: null,
    action: child.action || null,
    submenu: child.provider !== undefined || childrenOf(items, id).length > 0,
  }
}

function matches(row, query) {
  var value = String(query || "").toLowerCase()
  return row.label.toLowerCase().indexOf(value) >= 0
    || (row.chord !== undefined && row.chord.toLowerCase().indexOf(value) >= 0)
}

// Every provider is a function of the detail column, so an unknown name is an
// empty level rather than a dead menu.
function rowsFrom(providers, name, detail) {
  var source = (providers || {})[name]
  return source ? source(detail || "") : []
}

function rowsFor(items, level, query, providers) {
  var item = items[level]
  var normalizedQuery = String(query || "").toLowerCase()
  var filterMatches = function(row) { return matches(row, normalizedQuery) }

  if (item && item.provider !== undefined) {
    var rows = rowsFrom(providers, item.provider, "")
    return normalizedQuery.length === 0 ? rows : rows.filter(filterMatches)
  }
  if (normalizedQuery.length === 0) {
    return childrenOf(items, level).map(function(id) { return rowFor(items, id, level) })
  }

  var found = descendantsOf(items, level).map(function(id) { return rowFor(items, id, level) })
  if (level === "root") found = found.concat(rowsFrom(providers, "apps", "Apps"))
  return found.filter(function(row) { return row.enabled && filterMatches(row) })
    .sort(function(a, b) { return (a.detail ? 1 : 0) - (b.detail ? 1 : 0) })
}

function selectFirstEnabled(rows) {
  var index = (rows || []).findIndex(function(row) { return row.enabled })
  return index < 0 ? 0 : index
}

function moveIndex(rows, currentIndex, steps) {
  var list = rows || []
  var count = list.length
  if (count === 0) return currentIndex

  var delta = steps > 0 ? 1 : -1
  var index = currentIndex
  for (var moved = 0; moved < Math.abs(steps); moved++) {
    var candidate = index
    for (var tried = 0; tried < count; tried++) {
      candidate = (candidate + delta + count) % count
      if (list[candidate].enabled) break
    }
    index = candidate
  }
  return index
}

function parentLevel(level) {
  if (level === "root") return "root"
  return level.indexOf(".") >= 0 ? level.split(".").slice(0, -1).join(".") : "root"
}
