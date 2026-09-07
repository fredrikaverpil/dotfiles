
import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "NightlightModel.js" as NightlightModel

Item {
  id: root

  property var shell: null

  readonly property int nightTemperature: 4000
  readonly property int dayTemperature: 6500

  property string mode: "auto"
  property string overridePeriod: ""
  property string period: ""

  property real latitude: NaN
  property real longitude: NaN

  property bool reconciling: false
  property bool hasPendingTemperature: false
  property int pendingTemperature: 0
  property bool stateLoaded: false
  property var temperature: null
  readonly property bool enabled: stateLoaded && NightlightModel.isNightlight(temperature) // qmllint disable property-override

  function desiredTemperature() {
    return NightlightModel.desiredTemperature(mode, period, nightTemperature, dayTemperature)
  }

  function setMode(value) {
    var next = NightlightModel.modeState(value, period)
    mode = next.mode
    overridePeriod = next.overridePeriod
    apply(desiredTemperature())
  }

  function setNightlight(value) { setMode(value ? "on" : "off") }
  function toggle() { setNightlight(!enabled) }

  readonly property var backend: Ui.Compositor.nightlightBackend

  function tick() {
    period = NightlightModel.solarPeriod(new Date(), latitude, longitude)
    mode = NightlightModel.modeForPeriod(mode, period, overridePeriod)
    reconciling = true
    probe.running = true
  }

  // Concurrent starts race for the compositor's gamma manager, so apply requests are serialized.
  function apply(temp) {
    var decision = NightlightModel.applyDecision(temperature, temp, applyProcess.running)
    if (decision === "ignore") return
    root.temperature = temp
    root.stateLoaded = true

    if (decision === "queue") {
      root.pendingTemperature = temp
      root.hasPendingTemperature = true
      return
    }

    runApply(temp)
  }

  function runApply(temp) {
    applyProcess.command = ["bash", "-lc",
      backend.running + " || { " + backend.launch + " >/dev/null 2>&1 & sleep 1; }; " +
      "for _ in $(seq 10); do " +
      backend.set + Number(temp) + " >/dev/null 2>&1; sleep 0.2; " +
      "[ \"$(" + backend.get + " 2>/dev/null | grep -oE '[0-9]+' | head -n1)\" = \"" +
      Number(temp) + "\" ] && break; done"]
    applyProcess.running = true
  }

  Process {
    id: probe
    command: root.backend.probe
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.temperature = NightlightModel.temperatureFromOutput(text)
        root.stateLoaded = true
      }
    }
    onExited: function (exitCode) {
      if (exitCode !== 0) {
        root.temperature = null
        root.stateLoaded = true
      }
      if (root.reconciling) {
        root.reconciling = false
        root.apply(root.desiredTemperature())
      }
    }
  }

  Process {
    id: applyProcess
    onExited: {
      if (root.hasPendingTemperature) {
        root.hasPendingTemperature = false
        root.runApply(root.pendingTemperature)
        return
      }
      probe.running = true
    }
  }

  Process {
    id: locateProcess
    running: true
    command: ["sh", "-c",
      "tz=$(timedatectl show -p Timezone --value); " +
      "awk -v t=\"$tz\" '$3 == t { print $2; exit }' /etc/zoneinfo/zone.tab"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var coords = NightlightModel.coordsFromZoneTab(text)
        if (coords && isNaN(root.latitude) && isNaN(root.longitude)) {
          root.latitude = coords.latitude
          root.longitude = coords.longitude
        }
        root.tick()
      }
    }
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: root.tick()
  }

  IpcHandler {
    target: "nightlight"

    function status(): string {
      return JSON.stringify({
        enabled: root.enabled,
        temperature: root.temperature,
        mode: root.mode,
        period: root.period,
        latitude: root.latitude,
        longitude: root.longitude
      })
    }

    function enable(): string { root.setNightlight(true); return "enabled" }
    function disable(): string { root.setNightlight(false); return "disabled" }
    function auto(): string { root.setMode("auto"); return "auto" }

    function toggle(): string {
      var enabling = !root.enabled
      root.setNightlight(enabling)
      return enabling ? "enabled" : "disabled"
    }
  }
}
