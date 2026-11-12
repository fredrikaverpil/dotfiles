// SMHI's impact-based warnings: one file for all of Sweden, open data under
// CC BY 4.0. Each warning holds areas, each with its level, window and a
// GeoJSON outline, so a place's warnings are those whose outline holds it.

var URL =
  "https://opendata-download-warnings.smhi.se/ibww/api/version/1/warning.json";

// The same rolling window as WeatherModel's outlook.
var WINDOW = 12 * 60 * 60 * 1000;

// MESSAGE (long-running notices such as water shortage) has no colour, so it
// is left out.
var LEVELS = { YELLOW: "wood", ORANGE: "rose", RED: "rose" };
var RANK = { "": 0, wood: 1, rose: 2 };

// An icon per SMHI event code; an event added later gets the alert glyph.
var EVENT_GLYPHS = {
  WIND: "󰖝",
  WIND_MOUNTAINS: "󰖝",
  WIND_SEA: "󰖝",
  RAIN: "󰖖",
  SNOW: "󰖘",
  THUNDER: "󰖓",
  FLOODING: "󰞍",
  HIGH_FLOW: "󰞍",
  HIGH_SEALEVEL: "󰞍",
  LOW_SEA_LEVEL: "󰞍",
  BLACK_ICE: "󰜗",
  ICE_ACCRETION: "󰜗",
  FIRE: "󰈸",
  HIGH_TEMPERATURES: "󰔏",
  STRONG_COOLING: "󰔏",
  WATER_SHORTAGE: "󰖌",
};
var ALERT_GLYPH = "󰀦";

// Sea districts can reach over the coast; a place on land is not at sea.
var SEA_AREAS = "SWE_SEA_DISTRICTS";

function worst(a, b) {
  return (RANK[b] || 0) > (RANK[a] || 0) ? b : a;
}

function eventGlyph(code) {
  return EVENT_GLYPHS[code] || ALERT_GLYPH;
}

// One { icon, level } per distinct icon among warnings and risks, each at its
// worst level, worst first; ties keep their first appearance.
function glyphs(alerts) {
  var byIcon = {};
  var order = [];
  for (var i = 0; i < alerts.length; i++) {
    var alert = alerts[i];
    if (!byIcon[alert.icon]) {
      byIcon[alert.icon] = { icon: alert.icon, level: alert.level };
      order.push(alert.icon);
    } else {
      byIcon[alert.icon].level = worst(byIcon[alert.icon].level, alert.level);
    }
  }
  return order
    .map(function (icon, index) {
      return { glyph: byIcon[icon], index: index };
    })
    .sort(function (a, b) {
      return RANK[b.glyph.level] - RANK[a.glyph.level] || a.index - b.index;
    })
    .map(function (entry) {
      return entry.glyph;
    });
}

// Ray casting; GeoJSON positions are [longitude, latitude].
function inRing(ring, x, y) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    var xi = ring[i][0];
    var yi = ring[i][1];
    var xj = ring[j][0];
    var yj = ring[j][1];
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi)
      inside = !inside;
  }
  return inside;
}

// The first ring is the outline, the rest are holes.
function inPolygon(rings, x, y) {
  if (!rings || rings.length === 0 || !inRing(rings[0], x, y)) return false;
  for (var i = 1; i < rings.length; i++)
    if (inRing(rings[i], x, y)) return false;
  return true;
}

function contains(geometry, latitude, longitude) {
  if (!geometry || !geometry.coordinates) return false;
  if (geometry.type === "Polygon")
    return inPolygon(geometry.coordinates, longitude, latitude);
  if (geometry.type === "MultiPolygon") {
    for (var i = 0; i < geometry.coordinates.length; i++)
      if (inPolygon(geometry.coordinates[i], longitude, latitude)) return true;
  }
  return false;
}

function timeOf(value) {
  var when = Date.parse(String(value || ""));
  return isNaN(when) ? null : when;
}

function english(text) {
  return text && text.en ? String(text.en) : "";
}

// The warnings at a place whose window overlaps the next WINDOW, worst first,
// then soonest; null when the response does not read.
function warningsAt(raw, latitude, longitude, now) {
  var data;
  try {
    data = JSON.parse(String(raw || ""));
  } catch (error) {
    return null;
  }
  if (!Array.isArray(data)) return null;

  var from = (now instanceof Date ? now : new Date()).getTime();
  var found = [];
  for (var i = 0; i < data.length; i++) {
    var areas = data[i] && data[i].warningAreas ? data[i].warningAreas : [];
    for (var j = 0; j < areas.length; j++) {
      var area = areas[j];
      var code = area.warningLevel ? area.warningLevel.code : "";
      var level = LEVELS[code];
      var shape = area.area || {};
      if (!level) continue;
      if (shape.properties && shape.properties.code === SEA_AREAS) continue;
      var start = timeOf(area.approximateStart);
      var end = timeOf(area.approximateEnd);
      if (start !== null && start >= from + WINDOW) continue;
      if (end !== null && end <= from) continue;
      if (!contains(shape.geometry, latitude, longitude)) continue;
      var event = area.eventDescription || data[i].event || {};
      found.push({
        level: level,
        icon: eventGlyph(event.code),
        severity: english(area.warningLevel),
        event: english(area.eventDescription) || english(data[i].event),
        area: english(area.areaName),
        start: start,
        end: end,
      });
    }
  }
  found.sort(function (a, b) {
    var rank = RANK[b.level] - RANK[a.level];
    return rank !== 0 ? rank : (a.start || 0) - (b.start || 0);
  });
  return found;
}
