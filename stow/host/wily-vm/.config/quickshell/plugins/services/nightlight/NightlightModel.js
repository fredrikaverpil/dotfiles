
var IDENTITY_TEMPERATURE = 6000

var HORIZON = -0.833

var UNIX_EPOCH_JULIAN_DAY = 2440587.5
var J2000 = 2451545.0
var MS_PER_DAY = 86400000

function temperatureFromOutput(output) {
  var match = String(output === undefined || output === null ? "" : output).match(/[0-9]+/)
  return match ? Number(match[0]) : null
}

function isNightlight(temperature) {
  return temperature !== null && temperature !== undefined && temperature < IDENTITY_TEMPERATURE
}

// zone1970.tab omits zones such as Europe/Stockholm that timedatectl reports.
function coordsFromZoneTab(text) {
  var match = String(text || "").trim()
    .match(/^([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?$/)
  if (!match) return null

  function sexagesimal(sign, deg, min, sec) {
    var value = Number(deg) + Number(min) / 60 + (sec ? Number(sec) / 3600 : 0)
    return sign === "-" ? -value : value
  }

  return {
    latitude: sexagesimal(match[1], match[2], match[3], match[4]),
    longitude: sexagesimal(match[5], match[6], match[7], match[8])
  }
}

function radians(degrees) { return degrees * Math.PI / 180 }

function solarTimes(date, latitude, longitude) {
  if (!isFinite(latitude) || !isFinite(longitude)) return null

  var julianDay = date.getTime() / MS_PER_DAY + UNIX_EPOCH_JULIAN_DAY
  var day = Math.round(julianDay - J2000 - 0.0009) + 0.0009 - longitude / 360
  var meanAnomaly = (357.5291 + 0.98560028 * day) % 360
  var centre = 1.9148 * Math.sin(radians(meanAnomaly))
    + 0.02 * Math.sin(radians(2 * meanAnomaly))
    + 0.0003 * Math.sin(radians(3 * meanAnomaly))
  var eclipticLongitude = (meanAnomaly + centre + 180 + 102.9372) % 360
  var transit = J2000 + day
    + 0.0053 * Math.sin(radians(meanAnomaly))
    - 0.0069 * Math.sin(radians(2 * eclipticLongitude))
  var declination = Math.asin(Math.sin(radians(eclipticLongitude)) * Math.sin(radians(23.4397)))

  var hourAngle = (Math.sin(radians(HORIZON)) - Math.sin(radians(latitude)) * Math.sin(declination))
    / (Math.cos(radians(latitude)) * Math.cos(declination))
  if (hourAngle > 1 || hourAngle < -1) return null
  var offset = Math.acos(hourAngle) / (2 * Math.PI)

  function toDate(julian) { return new Date((julian - UNIX_EPOCH_JULIAN_DAY) * MS_PER_DAY) }
  return { sunrise: toDate(transit - offset), sunset: toDate(transit + offset) }
}

function solarPeriod(date, latitude, longitude) {
  var times = solarTimes(date, latitude, longitude)
  if (!times) {
    if (!isFinite(latitude) || !isFinite(longitude)) return ""
    var northernSummer = date.getUTCMonth() >= 3 && date.getUTCMonth() <= 8
    var sunUp = latitude >= 0 ? northernSummer : !northernSummer
    return sunUp ? "day" : "night"
  }
  return (date < times.sunrise || date >= times.sunset) ? "night" : "day"
}

function expiresOverride(mode, period, overridePeriod) {
  return mode !== "auto" && overridePeriod !== "" && period !== overridePeriod
}

function demo() {
  var assert = require("assert")

  assert.strictEqual(temperatureFromOutput("temperature: 4000\n"), 4000)
  assert.strictEqual(temperatureFromOutput(""), null)
  assert.strictEqual(isNightlight(4000), true)
  assert.strictEqual(isNightlight(6500), false)
  assert.strictEqual(isNightlight(null), false)

  assert.deepStrictEqual(coordsFromZoneTab("+5920+01803\n"),
    { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 })
  assert.deepStrictEqual(coordsFromZoneTab("-3352-01827"),
    { latitude: -(33 + 52 / 60), longitude: -(18 + 27 / 60) })
  assert.deepStrictEqual(coordsFromZoneTab("+404251-0740023"),
    { latitude: 40 + 42 / 60 + 51 / 3600, longitude: -(74 + 0 / 60 + 23 / 3600) })
  assert.strictEqual(coordsFromZoneTab("nonsense"), null)

  var stockholm = { latitude: 59 + 20 / 60, longitude: 18 + 3 / 60 }
  function minutesApart(a, b) { return Math.abs(a.getTime() - b.getTime()) / 60000 }

  var midsummer = solarTimes(new Date("2024-06-21T12:00:00Z"), stockholm.latitude, stockholm.longitude)
  assert.ok(minutesApart(midsummer.sunrise, new Date("2024-06-21T01:31:00Z")) < 5,
    "midsummer sunrise: " + midsummer.sunrise.toISOString())
  assert.ok(minutesApart(midsummer.sunset, new Date("2024-06-21T20:08:00Z")) < 5,
    "midsummer sunset: " + midsummer.sunset.toISOString())

  var midwinter = solarTimes(new Date("2024-12-21T12:00:00Z"), stockholm.latitude, stockholm.longitude)
  assert.ok(minutesApart(midwinter.sunrise, new Date("2024-12-21T07:44:00Z")) < 5,
    "midwinter sunrise: " + midwinter.sunrise.toISOString())
  assert.ok(minutesApart(midwinter.sunset, new Date("2024-12-21T13:48:00Z")) < 5,
    "midwinter sunset: " + midwinter.sunset.toISOString())

  assert.strictEqual(solarPeriod(new Date("2024-06-21T12:00:00Z"), stockholm.latitude, stockholm.longitude), "day")
  assert.strictEqual(solarPeriod(new Date("2024-06-21T21:00:00Z"), stockholm.latitude, stockholm.longitude), "night")
  assert.strictEqual(solarPeriod(new Date("2024-12-21T12:00:00Z"), stockholm.latitude, stockholm.longitude), "day")
  assert.strictEqual(solarPeriod(new Date("2024-12-21T15:00:00Z"), stockholm.latitude, stockholm.longitude), "night")

  assert.strictEqual(solarTimes(new Date("2024-06-21T12:00:00Z"), 78.2, 15.6), null)
  assert.strictEqual(solarPeriod(new Date("2024-06-21T12:00:00Z"), 78.2, 15.6), "day")
  assert.strictEqual(solarPeriod(new Date("2024-12-21T12:00:00Z"), 78.2, 15.6), "night")
  assert.strictEqual(solarPeriod(new Date(), NaN, NaN), "")

  assert.strictEqual(expiresOverride("on", "day", "day"), false)
  assert.strictEqual(expiresOverride("on", "night", "day"), true)
  assert.strictEqual(expiresOverride("off", "day", "night"), true)
  assert.strictEqual(expiresOverride("auto", "night", ""), false)
  assert.strictEqual(expiresOverride("on", "day", ""), false)

  console.log("ok")
}

if (typeof module !== "undefined") {
  module.exports = {
    IDENTITY_TEMPERATURE: IDENTITY_TEMPERATURE,
    temperatureFromOutput: temperatureFromOutput,
    isNightlight: isNightlight,
    coordsFromZoneTab: coordsFromZoneTab,
    solarTimes: solarTimes,
    solarPeriod: solarPeriod,
    expiresOverride: expiresOverride
  }
  if (require.main === module) demo()
}
