function gdkScale(scale) {
  var n = Number(scale)
  if (!isFinite(n) || n < 1) return 1
  return Math.round(n)
}
