// Scale arithmetic, ported from Omarchy's file at this path. Their brightness
// and multi-display helpers are not here: both rows are dim on this hardware.
// Run `node Model.js` for the self-check.

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

// Hyprland only accepts scales where the mode divides into whole logical
// pixels, in 1/120 steps, so a clean scale is a divisor of gcd(w*120, h*120).
// Rounds the request up to the nearest clean value, as upstream does.
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

// Which preset the monitor is on now. Hyprland reports a float, so this
// matches on the effective clean scale rather than comparing exactly.
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

// Several presets can collapse onto the same clean scale for a given mode.
// Keep the closest label for each, so stepping always changes what is shown.
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

// GTK draws its own UI at whole factors only, so a fractional monitor scale
// still has to pick an integer here. Upstream persists the same rounding.
// The two compositors' monitor queries folded into one shape. hyprctl lists
// every monitor and flags the focused one; `niri msg -j focused-output`
// answers with that one output directly, or null.
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
    // niri reports millihertz; hyprctl reports Hz, which is what the mode
    // string handed back to the compositor has to be in.
    refreshRate: mode.refresh_rate / 1000,
    scale: parsed.logical.scale
  }
}

function gdkScale(scale) {
  var n = Number(scale)
  if (!isFinite(n) || n < 1) return 1
  return Math.round(n)
}

function demo() {
  var assert = require("assert")

  assert.strictEqual(normalizeScale("1.6"), "1.6")
  assert.strictEqual(normalizeScale("nonsense"), "")

  // 1280x800, the VM's mode. gcd(153600, 96000) = 19200 units, so a clean
  // scale is any divisor of that over 120.
  assert.strictEqual(cleanScale(1, 1280, 800), "1")
  assert.strictEqual(cleanScale(2, 1280, 800), "2")
  assert.strictEqual(cleanScale(0, 1280, 800), "")
  assert.strictEqual(cleanScale(1, 0, 0), "")

  // 1920x1080 rejects most fractions: gcd(230400, 129600) = 43200 units.
  // 1.25 is 150 units, which does not divide it, so it rounds up.
  var laptop = cleanScale(1.25, 1920, 1080)
  assert.notStrictEqual(laptop, "")
  assert.ok(Number(laptop) >= 1.25, "clean scale rounds up, got " + laptop)
  assert.strictEqual(43200 % Math.round(Number(laptop) * 120), 0)

  // Every value offered must itself be clean, or applying it silently snaps.
  var presets = [1, 1.25, 1.6, 2, 3, 4]
  var offered = availableScales(presets, 1920, 1080)
  assert.ok(offered.length > 0)
  offered.forEach(function (value) {
    var effective = cleanScale(value, 1920, 1080)
    assert.notStrictEqual(effective, "", "no clean scale for " + value)
  })
  // No two entries may collapse onto the same effective scale.
  var effectives = offered.map(function (v) { return cleanScale(v, 1920, 1080) })
  assert.strictEqual(new Set(effectives).size, effectives.length)

  assert.strictEqual(matchingScaleIndex(presets, 1, 1280, 800), 0)
  assert.strictEqual(matchingScaleIndex(presets, 2, 1280, 800), 3)
  assert.strictEqual(matchingScaleIndex(presets, NaN, 1280, 800), -1)

  assert.strictEqual(gdkScale(1), 1)
  assert.strictEqual(gdkScale(1.25), 1)
  assert.strictEqual(gdkScale(1.6), 2)
  assert.strictEqual(gdkScale(2), 2)
  assert.strictEqual(gdkScale("nonsense"), 1)

  // Both monitor shapes normalize to the same fields.
  var hypr = focusedMonitor(JSON.stringify([
    { name: "eDP-1", width: 1920, height: 1080, refreshRate: 60, scale: 1, focused: false },
    { name: "Virtual-1", width: 1280, height: 800, refreshRate: 60, scale: 2, focused: true }
  ]), false)
  assert.deepStrictEqual(hypr, {
    name: "Virtual-1", width: 1280, height: 800, refreshRate: 60, scale: 2, focused: true
  })

  var niri = focusedMonitor(JSON.stringify({
    name: "Virtual-1",
    modes: [{ width: 1920, height: 1080, refresh_rate: 59997 },
            { width: 1280, height: 800, refresh_rate: 60000 }],
    current_mode: 1,
    logical: { x: 0, y: 0, width: 640, height: 400, scale: 2 }
  }), true)
  assert.deepStrictEqual(niri, {
    name: "Virtual-1", width: 1280, height: 800, refreshRate: 60, scale: 2
  })

  // A disabled output, and unparseable output, are both "no monitor".
  assert.strictEqual(focusedMonitor(JSON.stringify(null), true), null)
  assert.strictEqual(focusedMonitor("not json", false), null)

  console.log("ok")
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
  if (require.main === module) demo()
}
