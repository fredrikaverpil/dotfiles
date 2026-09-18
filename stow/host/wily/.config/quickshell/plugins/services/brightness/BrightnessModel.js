function percent(raw, max) {
  return max > 0 ? Math.round(Math.max(0, Math.min(max, raw)) * 100 / max) : 0
}

// Never fully off: a black panel looks like a dead machine.
function rawFor(value, max) {
  var floor = Math.max(1, Math.round(max / 100))
  return Math.max(floor, Math.min(max, Math.round(value * max / 100)))
}
