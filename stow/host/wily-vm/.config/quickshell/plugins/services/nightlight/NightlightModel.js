
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

function desiredTemperature(mode, period, nightTemperature, dayTemperature) {
  if (mode === "on") return nightTemperature
  if (mode === "off") return dayTemperature
  if (period === "") return NaN
  return period === "night" ? nightTemperature : dayTemperature
}

function modeState(mode, period) {
  return {
    mode: mode,
    overridePeriod: mode === "auto" ? "" : period,
  }
}

function modeForPeriod(mode, period, overridePeriod) {
  return expiresOverride(mode, period, overridePeriod) ? "auto" : mode
}

function applyDecision(currentTemperature, requestedTemperature, running) {
  if (!isFinite(requestedTemperature) || currentTemperature === requestedTemperature) return "ignore"
  return running ? "queue" : "start"
}

if (typeof module !== "undefined") {
  module.exports = {
    IDENTITY_TEMPERATURE: IDENTITY_TEMPERATURE,
    temperatureFromOutput: temperatureFromOutput,
    isNightlight: isNightlight,
    coordsFromZoneTab: coordsFromZoneTab,
    solarTimes: solarTimes,
    solarPeriod: solarPeriod,
    expiresOverride: expiresOverride,
    desiredTemperature: desiredTemperature,
    modeState: modeState,
    modeForPeriod: modeForPeriod,
    applyDecision: applyDecision,
  }
}
