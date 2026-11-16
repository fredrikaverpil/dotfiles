.pragma library

// state is { on, holds, owned }. The first hold turns it on, owning it only
// when it was off; the last release turns it off only when owned.
function hold(state, reason, on) {
  var holds = state.holds.filter(function (held) {
    return held !== reason;
  });
  if (on)
    return {
      on: true,
      holds: holds.concat([reason]),
      owned: state.owned || !state.on,
    };
  var release = holds.length === 0 && state.owned;
  return {
    on: release ? false : state.on,
    holds: holds,
    owned: release ? false : state.owned,
  };
}

// An IPC argument as a boolean.
function flag(value) {
  var normalized = String(value || "").toLowerCase();
  return (
    normalized === "true" ||
    normalized === "1" ||
    normalized === "on" ||
    normalized === "yes"
  );
}
