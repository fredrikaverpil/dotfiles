function rgb(hex) {
  var value = String(hex || "")
  var match = /^#([0-9a-f]{6})$/i.exec(value)
  if (!match) return ""
  var packed = match[1]
  return [
    parseInt(packed.slice(0, 2), 16),
    parseInt(packed.slice(2, 4), 16),
    parseInt(packed.slice(4, 6), 16),
  ].join(",")
}

function kdeglobalsWrite(dark, darkPalette, lightPalette) {
  var palette = dark ? darkPalette : lightPalette
  var set = function(key, hex) {
    return "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key "
      + key + " '" + rgb(hex) + "'; "
  }
  return set("BackgroundNormal", palette.bg) + set("ForegroundNormal", palette.fg)
}

function textScale(value, minimum, maximum) {
  var scale = Number(value)
  var min = minimum === undefined ? 0.8 : minimum
  var max = maximum === undefined ? 1.5 : maximum
  return isFinite(scale) && scale >= min && scale <= max ? scale : null
}

function observedTextScale(value) {
  var scale = parseFloat(String(value))
  return isFinite(scale) && scale > 0 ? scale : null
}
