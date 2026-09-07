function savedRecord(record) {
  return {
    app: record.app,
    appIcon: record.appIcon,
    summary: record.summary,
    body: record.body,
    image: record.image,
    urgency: record.urgency,
    timestamp: record.timestamp,
  }
}

function historyWith(history, record, limit) {
  var rows = Array.isArray(history) ? history : []
  if (!record || record.transient) return rows
  return [savedRecord(record)].concat(rows).slice(0, limit)
}

function loadedState(raw, limit) {
  var parsed = {}
  var valid = true
  try {
    parsed = JSON.parse(String(raw || ""))
  } catch (error) {
    valid = false
  }

  return {
    valid: valid,
    doNotDisturb: !!parsed.doNotDisturb,
    history: Array.isArray(parsed.history) ? parsed.history.slice(0, limit) : [],
  }
}

function stateText(doNotDisturb, history) {
  return JSON.stringify({
    version: 1,
    doNotDisturb: !!doNotDisturb,
    history: Array.isArray(history) ? history : [],
  }, null, 2) + "\n"
}

function replacePopup(rows, record) {
  var next = Array.isArray(rows) ? rows.slice() : []
  var index = next.findIndex(function(row) { return row.key === record.key })
  if (index >= 0) next[index] = record
  return next
}

function withoutRecord(rows, key) {
  return (Array.isArray(rows) ? rows : []).filter(function(row) { return row.key !== key })
}

function dndValue(value) {
  var normalized = String(value || "").toLowerCase()
  return normalized === "true" || normalized === "1" || normalized === "on" || normalized === "yes"
}
