
function normalizeScale(scale) {
  var n = parseFloat(String(scale || ""))
  if (!isFinite(n)) return ""
  return String(Math.round(n * 100) / 100)
}

function gcd(a, b) {
  while (b) {
    var remainder = a % b
    a = b
    b = remainder
  }
  return a
}

// Hyprland accepts only 1/120 scales that leave whole logical pixels.
function cleanScale(scale, width, height) {
  var requested = Number(scale)
  var modeWidth = Number(width)
  var modeHeight = Number(height)
  if (!isFinite(requested) || !isFinite(modeWidth) || !isFinite(modeHeight)
      || requested <= 0 || modeWidth <= 0 || modeHeight <= 0) return ""

  var divisor = gcd(Math.round(modeWidth * 120), Math.round(modeHeight * 120))
  var scaleUnits = Math.round(requested * 120)
  if (scaleUnits > divisor) scaleUnits = divisor
  while (divisor % scaleUnits !== 0) scaleUnits++
  return normalizeScale(scaleUnits / 120)
}

function matchingScaleIndex(scales, currentScale, width, height) {
  var current = Number(currentScale)
  if (!Array.isArray(scales) || !isFinite(current)) return -1

  var bestIndex = -1
  var bestDistance = Infinity
  var normalizedCurrent = normalizeScale(current)
  for (var i = 0; i < scales.length; i++) {
    if (cleanScale(scales[i], width, height) !== normalizedCurrent) continue

    var distance = Math.abs(Number(scales[i]) - current)
    if (distance < bestDistance) {
      bestIndex = i
      bestDistance = distance
    }
  }
  return bestIndex
}

function availableScales(scales, width, height) {
  if (!Array.isArray(scales) || Number(width) <= 0 || Number(height) <= 0) return scales || []

  var byEffectiveScale = {}
  for (var i = 0; i < scales.length; i++) {
    var requested = Number(scales[i])
    var effective = Number(cleanScale(requested, width, height))

    if (!isFinite(requested) || !isFinite(effective)) continue

    var key = normalizeScale(effective)
    var existing = byEffectiveScale[key]
    if (!existing || Math.abs(requested - effective) < existing.distance) {
      byEffectiveScale[key] = {
        value: String(scales[i]),
        index: i,
        distance: Math.abs(requested - effective)
      }
    }
  }

  return Object.keys(byEffectiveScale)
    .map(function (key) { return byEffectiveScale[key] })
    .sort(function (a, b) { return a.index - b.index })
    .map(function (candidate) { return candidate.value })
}

// hyprctl returns all outputs; niri returns only the focused output in a different shape.
function focusedMonitor(raw, niri) {
  var parsed
  try {
    parsed = JSON.parse(String(raw || ""))
  } catch (error) {
    return null
  }

  if (!niri) {
    if (!Array.isArray(parsed)) return null
    return parsed.find(function (m) { return m && m.focused })
      || parsed.find(function (m) { return m && Number(m.width) > 0 })
      || null
  }

  if (!parsed || !parsed.logical || parsed.current_mode === null
      || parsed.current_mode === undefined) return null
  var mode = (parsed.modes || [])[parsed.current_mode]
  if (!mode) return null

  return {
    name: parsed.name,
    width: mode.width,
    height: mode.height,
    refreshRate: mode.refresh_rate / 1000,
    scale: parsed.logical.scale
  }
}

function gdkScale(scale) {
  var n = Number(scale)
  if (!isFinite(n) || n < 1) return 1
  return Math.round(n)
}

if (typeof module !== "undefined") {
  module.exports = {
    normalizeScale: normalizeScale,
    cleanScale: cleanScale,
    matchingScaleIndex: matchingScaleIndex,
    availableScales: availableScales,
    focusedMonitor: focusedMonitor,
    gdkScale: gdkScale
  }
}
