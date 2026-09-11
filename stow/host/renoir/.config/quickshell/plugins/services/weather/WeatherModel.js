var DEFAULT_INTERVAL = 30 * 60 * 1000
var MINIMUM_INTERVAL = 5 * 60 * 1000
var MAXIMUM_INTERVAL = 60 * 60 * 1000
// MET asks that a request not be repeated before Expires. Land after it, not
// on it, so clock skew between us and their cache cannot make us early.
var EXPIRY_MARGIN = 60 * 1000

var DAY_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

var GLYPHS = {
  sun: "󰖙",
  moon: "󰖔",
  partly: "󰖕",
  partlyNight: "󰼱",
  cloud: "󰖐",
  fog: "󰖑",
  rain: "󰖗",
  snow: "󰖘",
  storm: "󰙾",
}

function coordinate(value) {
  var number = parseFloat(value)
  return isFinite(number) ? Math.round(number * 100) / 100 : null
}

function forecastUrl(latitude, longitude) {
  var lat = coordinate(latitude)
  var lon = coordinate(longitude)
  if (lat === null || lon === null) return ""
  return "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=" + lat + "&lon=" + lon
}

// MET's terms require honouring Expires. The clamp guards against a missing,
// stale, or absurdly distant header.
function expiresInterval(header, now) {
  var at = Date.parse(String(header || "").replace(/^\s+|\s+$/g, ""))
  if (isNaN(at)) return DEFAULT_INTERVAL
  var reference = now instanceof Date ? now.getTime() : Date.now()
  return Math.min(MAXIMUM_INTERVAL, Math.max(MINIMUM_INTERVAL, at - reference + EXPIRY_MARGIN))
}

// symbol_code carries its own day/night suffix, so no solar maths is needed.
// polartwilight has the sun below the horizon; draw it as night.
function isNight(symbol) {
  var value = String(symbol || "")
  return value.indexOf("_night") >= 0 || value.indexOf("_polartwilight") >= 0
}

// Substring tests rather than a table of every symbol_code: MET compounds them
// freely and its own legend misspells two as "lights...".
function kind(symbol) {
  var base = String(symbol || "").split("_")[0]
  if (base === "") return ""
  if (base.indexOf("thunder") >= 0) return "storm"
  if (base.indexOf("snow") >= 0 || base.indexOf("sleet") >= 0) return "snow"
  if (base.indexOf("rain") >= 0) return "rain"
  if (base === "fog") return "fog"
  if (base === "partlycloudy") return "partly"
  if (base === "clearsky" || base === "fair") return "sun"
  return "cloud"
}

function icon(symbol) {
  var night = isNight(symbol)
  switch (kind(symbol)) {
  case "sun": return night ? GLYPHS.moon : GLYPHS.sun
  case "partly": return night ? GLYPHS.partlyNight : GLYPHS.partly
  case "fog": return GLYPHS.fog
  case "rain": return GLYPHS.rain
  case "snow": return GLYPHS.snow
  case "storm": return GLYPHS.storm
  case "cloud": return GLYPHS.cloud
  default: return ""
  }
}

function condition(symbol) {
  var base = String(symbol || "").split("_")[0]
  if (base === "") return ""
  if (base === "clearsky") return "Clear sky"
  if (base === "fair") return "Fair"
  if (base === "partlycloudy") return "Partly cloudy"
  if (base === "cloudy") return "Cloudy"
  if (base === "fog") return "Fog"

  var rest = base
  var thunder = rest.indexOf("andthunder") >= 0
  rest = rest.replace("andthunder", "")
  var showers = rest.indexOf("showers") >= 0
  rest = rest.replace("showers", "")

  var intensity = ""
  if (rest.indexOf("light") === 0) {
    intensity = "Light "
    rest = rest.replace(/^lights?/, "")
  } else if (rest.indexOf("heavy") === 0) {
    intensity = "Heavy "
    rest = rest.slice(5)
  }

  var text = intensity + (rest === "" ? "precipitation" : rest) + (showers ? " showers" : "")
  if (thunder) text += " and thunder"
  return text.charAt(0).toUpperCase() + text.slice(1)
}

function temperature(value) {
  var number = parseFloat(value)
  return isFinite(number) ? Math.round(number) + "°" : ""
}

function dayKey(date) {
  var month = date.getMonth() + 1
  var day = date.getDate()
  return date.getFullYear() + "-" + (month < 10 ? "0" : "") + month + "-" + (day < 10 ? "0" : "") + day
}

function dayName(key) {
  var date = new Date(String(key || "") + "T12:00:00")
  return isNaN(date.getTime()) ? "" : DAY_NAMES[date.getDay()]
}

function symbolOf(entry) {
  var data = entry && entry.data ? entry.data : {}
  var next = data.next_1_hours || data.next_6_hours || data.next_12_hours
  return next && next.summary ? String(next.summary.symbol_code || "") : ""
}

// MET keeps the elapsed hour at the head of the timeseries, so series[0]'s
// next_1_hours symbol can describe weather that is already over. Take the
// latest entry that has started.
function currentFrom(series, now) {
  var reference = (now instanceof Date ? now : new Date()).getTime()
  var entry = series[0]
  for (var i = 1; i < series.length; i++) {
    var when = Date.parse(String(series[i].time || ""))
    if (isNaN(when) || when > reference) break
    entry = series[i]
  }
  var details = entry && entry.data && entry.data.instant ? entry.data.instant.details : null
  if (!details) return null
  return {
    symbol: symbolOf(entry),
    temperature: details.air_temperature,
    wind: details.wind_speed,
    humidity: details.relative_humidity,
  }
}

// locationforecast has no daily aggregation, so the extremes come from the
// timeseries itself. It thins to 6-hourly beyond ~2.5 days, which can clip a
// short peak on the last day.
function dailyFrom(series, now) {
  var today = dayKey(now instanceof Date ? now : new Date())
  var order = []
  var byDay = {}

  for (var i = 0; i < series.length; i++) {
    var entry = series[i]
    var when = new Date(String(entry.time || ""))
    if (isNaN(when.getTime())) continue

    var key = dayKey(when)
    if (key <= today) continue

    if (!byDay[key]) {
      byDay[key] = { date: key, name: dayName(key), maximum: null, minimum: null, symbol: "" }
      byDay[key].distance = Infinity
      order.push(key)
    }
    var day = byDay[key]

    var details = entry.data && entry.data.instant ? entry.data.instant.details : null
    var value = details ? parseFloat(details.air_temperature) : NaN
    if (isFinite(value)) {
      if (day.maximum === null || value > day.maximum) day.maximum = value
      if (day.minimum === null || value < day.minimum) day.minimum = value
    }

    // The sky closest to midday stands for the whole day.
    var distance = Math.abs(when.getHours() - 12)
    var symbol = symbolOf(entry)
    if (symbol !== "" && distance < day.distance) {
      day.distance = distance
      day.symbol = symbol
    }
  }

  return order.slice(0, 3).map(function (key) {
    var day = byDay[key]
    return { date: day.date, name: day.name, symbol: day.symbol, maximum: day.maximum, minimum: day.minimum }
  })
}

function parse(raw, now) {
  var data = null
  try {
    data = JSON.parse(String(raw || ""))
  } catch (error) {
    return null
  }

  var series = data && data.properties ? data.properties.timeseries : null
  if (!series || series.length === 0) return null

  var current = currentFrom(series, now)
  if (!current) return null
  return { current: current, days: dailyFrom(series, now) }
}
