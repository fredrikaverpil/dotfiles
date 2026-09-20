import QtQuick
import Quickshell.Io

import "TimezoneModel.js" as Model
import "ZonesModel.js" as Zones

Item {
  id: root

  // timedated owns the zone and persists it in /etc/localtime. The shell reads
  // and drives it; a second copy in the shell's own state could disagree with
  // the system every other process reads.
  property var info: Model.parse("")
  property string lastError: ""

  // date(1) and zdump only run while the panel is on screen.
  property bool polling: false

  readonly property string zone: info.zone

  function refresh() {
    if (probe.running) return
    probe.running = true
  }

  function setZone(name) {
    const zone = String(name || "")
    if (zone.length === 0 || apply.running) return false
    lastError = ""
    apply.command = ["timedatectl", "set-timezone", zone]
    apply.running = true
    return true
  }

  function resetZone() {
    return setZone(Zones.home.zone)
  }

  onPollingChanged: if (polling) refresh()

  Process {
    id: probe
    command: ["sh", "-c",
      'tz=$(timedatectl show -p Timezone --value); ' +
      'year=$(date +%Y); ' +
      'printf "zone|%s\\n" "$tz"; ' +
      'printf "ntp|%s\\n" "$(timedatectl show -p NTPSynchronized --value)"; ' +
      'date "+clock|%H:%M:%S|%Y-%m-%d|%a|%z|%Z"; ' +
      'date -u "+utc|%H:%M:%S|%Y-%m-%d"; ' +
      // A window around this year covers the change just past and the next two
      // ahead; zdump's own out-of-range sentinel lines do not parse.
      'zdump -v -c "$((year-1)),$((year+2))" "$tz" | sed "s/^/dump|/"']
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.info = Model.parse(text, Date.now())
    }
  }

  Process {
    id: apply
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.lastError = String(text || "").replace(/^\s+|\s+$/g, "")
    }
    // Setting the zone needs polkit, and the dialog can be dismissed. Re-read
    // rather than assume the change landed.
    onExited: root.refresh()
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.polling
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()
}
