// Nightlight, ported from Omarchy's service at this path, plus the solar
// schedule they leave to hand-written hyprsunset profiles. hyprsunset takes
// fixed clock times only, so the schedule lives here and hyprsunset.conf
// stays inert.

import QtQuick
import Quickshell
import Quickshell.Io

import "NightlightModel.js" as NightlightModel

Item {
  id: root

  property var shell: null

  // Omarchy's pair, kept identical so a temperature set from either side
  // reads back the same on the other.
  readonly property int nightTemperature: 4000
  readonly property int dayTemperature: 6500

  // "auto" follows the sun. "on" and "off" pin it until the next sunrise or
  // sunset, which is what Night Shift's manual toggle does; overridePeriod is
  // the solar period the override was made in, and the tick expires it when
  // that changes.
  property string mode: "auto"
  property string overridePeriod: ""
  property string period: ""

  // From the system timezone unless something assigns them first; see
  // locateProcess below.
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

  // Runs every minute: crosses the solar boundary, expires a manual override
  // on the far side of it, and re-asserts the temperature. That last part is
  // also what heals hyprsunset's own morning `identity` profile, which
  // otherwise clobbers a runtime temperature once a day.
  function tick() {
    period = NightlightModel.solarPeriod(new Date(), latitude, longitude)
    if (NightlightModel.expiresOverride(mode, period, overridePeriod)) mode = "auto"
    // Read the real temperature before deciding, or the reconcile below is
    // made against the previous minute's reading and an outside change takes
    // two ticks to correct. Only a tick reconciles: the probe that follows
    // every apply must not turn a temperature that will not stick into an
    // apply loop.
    reconciling = true
    probe.running = true
  }

  function apply(temp) {
    if (!isFinite(temp) || temperature === temp) return
    root.temperature = temp
    root.stateLoaded = true

    // Upstream's guard, and it does more than order the writes: the apply
    // command starts hyprsunset when none is running, and that check is not
    // atomic. Two applies overlapping while it is coming up each launch one,
    // and the loser exits with "A CTM manager is already running" plus a
    // stack trace in the journal. Seen live.
    if (applyProcess.running) {
      root.pendingTemperature = temp
      root.hasPendingTemperature = true
      return
    }

    runApply(temp)
  }

  function runApply(temp) {
    // Upstream's retry loop, from bin/omarchy-toggle-nightlight: a freshly
    // started hyprsunset applies its own default at the end of its boot and
    // overwrites anything set before then.
    applyProcess.command = ["bash", "-lc",
      "pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }; " +
      "for _ in $(seq 10); do " +
      "hyprctl hyprsunset temperature " + Number(temp) + " >/dev/null 2>&1; sleep 0.2; " +
      "[ \"$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+' | head -n1)\" = \"" +
      Number(temp) + "\" ] && break; done"]
    applyProcess.running = true
  }

  Process {
    id: probe
    command: ["hyprctl", "hyprsunset", "temperature"]
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

  // The zone's principal city, which is up to a few hundred kilometres off
  // for a large zone -- around fifteen minutes of winter sunset between
  // Stockholm and Malmo. Fine for a blue-light filter, and it follows the
  // laptop when the timezone changes.
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

    // enable/disable rather than the plan's on/off: it is what upstream's
    // handler and our idle service both call these.
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
