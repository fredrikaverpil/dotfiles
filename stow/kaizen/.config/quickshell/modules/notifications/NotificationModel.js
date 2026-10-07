// What a card draws from a live record: its NotificationLogic.snapshotOf fields.
function savedRecord(record) {
  return {
    app: record.app,
    appIcon: record.appIcon,
    summary: record.summary,
    body: record.body,
    image: record.image,
    icon: record.icon,
    badgeEmoji: record.badgeEmoji,
    border: record.border,
    borderAnimation: record.borderAnimation,
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
    doNotDisturb: !!parsed.doNotDisturb,
    dndSince: Number(parsed.dndSince) || 0,
    history: Array.isArray(parsed.history)
      ? parsed.history.slice(0, limit)
      : [],
  };
}

function stateText(doNotDisturb, history, dndSince) {
  return (
    JSON.stringify(
      {
        version: 1,
        doNotDisturb: !!doNotDisturb,
        dndSince: dndSince || 0,
        history: Array.isArray(history) ? history : [],
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

// state is { doNotDisturb, holds, owned }. The first hold turns DnD on, owning
// it only when it was off; the last release turns it off only when owned.
function dndHold(state, reason, on) {
  var holds = state.holds.filter(function (held) {
    return held !== reason;
  });
  if (on)
    return {
      doNotDisturb: true,
      holds: holds.concat([reason]),
      owned: state.owned || !state.doNotDisturb,
    };
  var release = holds.length === 0 && state.owned;
  return {
    doNotDisturb: release ? false : state.doNotDisturb,
    holds: holds,
    owned: release ? false : state.owned,
  };
}

function dndValue(value) {
  var normalized = String(value || "").toLowerCase();
  return (
    normalized === "true" ||
    normalized === "1" ||
    normalized === "on" ||
    normalized === "yes"
  );
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
