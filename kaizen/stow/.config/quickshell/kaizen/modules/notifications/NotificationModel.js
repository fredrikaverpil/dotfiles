// What a card draws from a live record: its NotificationLogic.snapshotOf fields.
function savedRecord(record) {
  return {
    app: record.app,
    appIcon: record.appIcon,
    summary: record.summary,
    body: record.body,
    image: record.image,
    icon: record.icon,
    badgeIcon: record.badgeIcon,
    badgeEmoji: record.badgeEmoji,
    border: record.border,
    animation: record.animation,
    actions: record.actions,
    urgency: record.urgency,
    timestamp: record.timestamp,
  };
}

// Critical rows first, then the rest, each newest first; the cap drops the
// oldest non-critical row first.
function historyWith(history, record, limit, critical) {
  var rows = Array.isArray(history) ? history : [];
  if (!record || record.transient) return rows;
  rows = [savedRecord(record)].concat(rows);
  return rows
    .filter(function (row) {
      return row.urgency === critical;
    })
    .concat(
      rows.filter(function (row) {
        return row.urgency !== critical;
      }),
    )
    .slice(0, limit);
}

// Quickshell serves an app's raw image data only to the process that
// received it.
var processImage = "image://qsimage/";

// The row as the state file keeps it: without an image of this process.
function storedRecord(row) {
  return row && String(row.image || "").indexOf(processImage) === 0
    ? Object.assign({}, row, { image: "" })
    : row;
}

function loadedState(raw, limit) {
  var parsed = {};
  var valid = true;
  try {
    parsed = JSON.parse(String(raw || ""));
  } catch (error) {
    valid = false;
  }

  return {
    valid: valid,
    holding: !!parsed.holding,
    holdingSince: Number(parsed.holdingSince) || 0,
    owned: !!parsed.owned,
    history: Array.isArray(parsed.history)
      ? parsed.history.slice(0, limit).map(storedRecord)
      : [],
  };
}

function stateText(holding, history, holdingSince, owned) {
  return (
    JSON.stringify(
      {
        version: 1,
        holding: !!holding,
        holdingSince: holdingSince || 0,
        owned: !!owned,
        history: Array.isArray(history) ? history.map(storedRecord) : [],
      },
      null,
      2,
    ) + "\n"
  );
}

function replacePopup(rows, record) {
  var next = Array.isArray(rows) ? rows.slice() : [];
  var index = next.findIndex(function (row) {
    return row.key === record.key;
  });
  if (index >= 0) next[index] = record;
  return next;
}

function withoutIndex(rows, index) {
  var next = Array.isArray(rows) ? rows.slice() : [];
  if (index < 0 || index >= next.length) return next;
  next.splice(index, 1);
  return next;
}

function withoutRecord(rows, key) {
  return (Array.isArray(rows) ? rows : []).filter(function (row) {
    return row.key !== key;
  });
}

function step(index, delta, count) {
  return count > 0 ? (index + delta + count) % count : 0;
}

function stepKey(rows, key, delta) {
  if (rows.length === 0) return "";
  var index = rows.findIndex(function (row) {
    return row.key === key;
  });
  return rows[step(index, delta, rows.length)].key;
}

// The row taking the removed row's place, else the new last row.
function keyAfter(rows, key) {
  var index = rows.findIndex(function (row) {
    return row.key === key;
  });
  var rest = withoutRecord(rows, key);
  if (index < 0 || rest.length === 0) return "";
  return rest[Math.min(index, rest.length - 1)].key;
}
