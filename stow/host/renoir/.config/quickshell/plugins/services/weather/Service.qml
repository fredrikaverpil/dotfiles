import QtQuick
import Quickshell.Io

import "PlacesModel.js" as Places
import "WeatherModel.js" as Model

Item {
  id: root

  // MET blocks generic User-Agents and requires contact information; the
  // repository URL is one of the forms their terms accept.
  readonly property string userAgent: "wily-shell/1.0 github.com/fredrikaverpil/dotfiles"

  property real latitude: Places.home.latitude
  property real longitude: Places.home.longitude
  property string place: Places.home.name
  property var current: null
  property var days: []
  property bool failed: false
  property var updatedAt: null

  readonly property bool busy: fetch.running
  readonly property bool ready: current !== null
  readonly property string icon: current ? Model.icon(current.symbol) : "󰖐"
  readonly property string condition: current ? Model.condition(current.symbol) : ""
  readonly property string temperature: current ? Model.temperature(current.temperature) : ""
  readonly property string wind: current && isFinite(current.wind) ? Math.round(current.wind) + " m/s" : ""
  readonly property string humidity: current && isFinite(current.humidity) ? Math.round(current.humidity) + "%" : ""
  readonly property int pollMinutes: Math.round(poll.interval / 60000)

  // A switch made while the previous city is still in flight must not be
  // dropped: the next scheduled poll can be an hour away.
  property bool queued: false

  function refresh() {
    if (fetch.running) {
      queued = true
      return
    }
    fetch.command = fetchCommand()
    fetch.running = true
  }

  // Travel is rare enough not to justify an IP-geolocation service; move the
  // location by hand instead.
  function setLocation(newLatitude, newLongitude, name) {
    const lat = Model.coordinate(newLatitude)
    const lon = Model.coordinate(newLongitude)
    if (lat === null || lon === null) return false

    latitude = lat
    longitude = lon
    place = String(name || "").length > 0 ? String(name) : lat + ", " + lon
    current = null
    days = []
    refresh()
    return true
  }

  function resetLocation() {
    setLocation(Places.home.latitude, Places.home.longitude, Places.home.name)
  }

  // Cache plus If-Modified-Since is required by MET's terms; -w prints the
  // Expires header ahead of the body so the poll can honour it. The cache is
  // per-location: one shared file would answer 304 after a location change and
  // serve the previous city's forecast under the new name.
  function fetchCommand() {
    return ["sh", "-c",
      'set -e; ' +
      'directory="${XDG_CACHE_HOME:-$HOME/.cache}/wily-shell"; ' +
      'cache="$directory/weather-' + latitude + '_' + longitude + '.json"; ' +
      'mkdir -p "$directory"; ' +
      'if [ -f "$cache" ]; then set -- -z "$cache"; fi; ' +
      'curl -sf -m 15 -A "' + userAgent + '" -o "$cache.new" "$@" -w "%header{expires}\\n" ' +
      '"' + Model.forecastUrl(latitude, longitude) + '"; ' +
      'if [ -s "$cache.new" ]; then mv "$cache.new" "$cache"; else rm -f "$cache.new"; fi; ' +
      'cat "$cache"']
  }

  function apply(text) {
    const separator = text.indexOf("\n")
    const report = Model.parse(separator < 0 ? text : text.slice(separator + 1))
    if (!report) {
      failed = true
      return
    }
    current = report.current
    days = report.days
    failed = false
    updatedAt = new Date()
    poll.interval = Model.expiresInterval(separator < 0 ? "" : text.slice(0, separator))
  }

  Process {
    id: fetch
    stdout: StdioCollector {
      onStreamFinished: root.apply(text)
    }
    // Deferred: `running` and the collector settle after this signal.
    onExited: {
      if (!root.queued) return
      root.queued = false
      Qt.callLater(root.refresh)
    }
  }

  Timer {
    id: poll
    interval: 30 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()
}
