import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "PlacesModel.js" as Places
import "WeatherModel.js" as Model

Item {
  id: root

  // MET blocks generic User-Agents and requires contact information; the
  // repository URL is one of the forms their terms accept.
  readonly property string userAgent: "kaizen-shell/1.0 github.com/fredrikaverpil/dotfiles"
  readonly property string statePath: Ui.Paths.state + "/weather.json"

  // Places.home seeds the first run only; the saved pick replaces it on load.
  property real latitude: Places.home.latitude
  property real longitude: Places.home.longitude
  property string place: Places.home.name
  property bool stateLoaded: false
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

  // Travel is rare enough not to justify an IP-geolocation service, and the
  // ThinkPads have no GNSS to read: the place is picked by hand. It is saved,
  // so a trip costs one choice rather than one per session.
  function setLocation(newLatitude, newLongitude, name) {
    const lat = Model.coordinate(newLatitude)
    const lon = Model.coordinate(newLongitude)
    if (lat === null || lon === null) return false

    latitude = lat
    longitude = lon
    place = String(name || "").length > 0 ? String(name) : lat + ", " + lon
    current = null
    days = []
    saveState()
    refresh()
    return true
  }

  function resetLocation() {
    setLocation(Places.home.latitude, Places.home.longitude, Places.home.name)
  }

  function saveState() {
    if (!stateLoaded) return
    stateFile.setText(JSON.stringify({
      version: 1, latitude: latitude, longitude: longitude, place: place
    }) + "\n")
  }

  function fetchCommand() {
    return ["sh", Quickshell.shellPath("plugins/services/weather/fetch.sh"),
      Ui.Paths.cache, String(latitude), String(longitude),
      Model.forecastUrl(latitude, longitude), userAgent]
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

  // The first fetch waits for this: starting on Places.home and correcting
  // afterwards would spend two MET requests to show the wrong city first.
  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      const saved = Model.loadedLocation(text(), Places.home)
      root.latitude = saved.latitude
      root.longitude = saved.longitude
      root.place = saved.name
      root.stateLoaded = true
      root.refresh()
    }
    onLoadFailed: {
      root.stateLoaded = true
      root.refresh()
    }
  }
}
