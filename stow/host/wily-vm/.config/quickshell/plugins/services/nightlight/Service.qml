// hyprsunset takes fixed clock times only, so the solar schedule lives here
// and hyprsunset.conf stays inert. The daemon underneath differs per
// compositor -- see Ui/Compositor.qml's nightlightBackend.

import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "NightlightModel.js" as NightlightModel

Item {
  id: root

  property var shell: null

  readonly property int nightTemperature: 4000
  readonly property int dayTemperature: 6500

  // "auto" follows the sun; "on" and "off" pin it until the next crossing.
  // overridePeriod is the solar period the override was made in, and the tick
  // expires it when that changes.
  property string mode: "auto"
  property string overridePeriod: ""
  property string period: ""

  // From the system timezone unless assigned first; see locateProcess.
  property real latitude: NaN
  property real longitude: NaN

  property bool reconciling: false
  property bool hasPendingTemperature: false
  property int pendingTemperature: 0
  property bool stateLoaded: false
  property var temperature: null
  readonly property bool enabled: stateLoaded && NightlightModel.isNightlight(temperature)

  function desiredTemperature() {
    if (mode === "on") return nightTemperature
    if (mode === "off") return dayTemperature
    if (period === "") return NaN // location not known yet, so leave it alone
    return period === "night" ? nightTemperature : dayTemperature
  }

  function setMode(value) {
    mode = value
    overridePeriod = value === "auto" ? "" : period
    apply(desiredTemperature())
  }

  function setNightlight(value) { setMode(value ? "on" : "off") }
  function toggle() { setNightlight(!enabled) }

  readonly property var backend: Ui.Compositor.nightlightBackend

  // Every minute. Re-asserting the temperature is also what heals hyprsunset's
  // morning `identity` profile, which otherwise clobbers it once a day.
  function tick() {
    period = NightlightModel.solarPeriod(new Date(), latitude, longitude)
    if (NightlightModel.expiresOverride(mode, period, overridePeriod)) mode = "auto"
    // Read before deciding, or an outside change takes two ticks to correct.
    // Only a tick reconciles: the probe after every apply must not turn a
    // temperature that will not stick into an apply loop.
    reconciling = true
    probe.running = true
  }

  function apply(temp) {
    if (!isFinite(temp) || temperature === temp) return
    root.temperature = temp
    root.stateLoaded = true

    // The apply command starts the daemon when none is running, and that check
    // is not atomic: two overlapping applies each launch one, and the
    // hyprsunset loser dies with "A CTM manager is already running".
    if (applyProcess.running) {
      root.pendingTemperature = temp
      root.hasPendingTemperature = true
      return
    }

    runApply(temp)
  }

  function runApply(temp) {
    // A freshly started hyprsunset applies its own default at the end of its
    // boot, overwriting anything set before then; hence the retry loop.
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

  // The zone's principal city: up to a few hundred kilometres off for a large
  // zone (~15 min of winter sunset between Stockholm and Malmo), which is fine
  // for a blue-light filter and follows the laptop when the timezone changes.
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
