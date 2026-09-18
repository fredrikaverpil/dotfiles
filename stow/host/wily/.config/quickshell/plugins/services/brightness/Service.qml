import QtQuick
import Quickshell.Io

import "BrightnessModel.js" as Model

Item {
  id: root

  readonly property int step: 5
  property string device: ""
  property int max: 0
  property int raw: 0
  property bool pending: false
  readonly property bool present: device !== "" && max > 0
  readonly property int percent: Model.percent(raw, max)

  function refresh() { if (present) current.reload() }

  function set(value) {
    if (!present) return
    raw = Model.rawFor(value, max)
    if (setter.running) pending = true
    else apply()
  }

  function adjust(delta) { set(percent + delta) }

  // logind lets the active session write the backlight without udev rules or group membership.
  function apply() {
    setter.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
      "org.freedesktop.login1.Session", "SetBrightness", "ssu", "backlight", device, String(raw)]
    setter.running = true
  }

  // Serialized so key repeat cannot land an older value last.
  Process {
    id: setter
    onExited: if (root.pending) {
      root.pending = false
      root.apply()
    }
  }

  Process {
    running: true
    command: ["ls", "/sys/class/backlight"]
    stdout: StdioCollector {
      onStreamFinished: root.device = text.trim().split("\n")[0] || ""
    }
  }

  FileView {
    path: root.device ? "/sys/class/backlight/" + root.device + "/max_brightness" : ""
    printErrors: false
    onLoaded: root.max = parseInt(text()) || 0
  }

  // sysfs emits no change events, so this is re-read when the panel opens.
  FileView {
    id: current
    path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
    printErrors: false
    onLoaded: root.raw = parseInt(text()) || 0
  }

  IpcHandler {
    target: "brightness"

    function up(): void { root.adjust(root.step) }
    function down(): void { root.adjust(-root.step) }
    function set(percent: int): void { root.set(percent) }
    function status(): string {
      return JSON.stringify({ device: root.device, percent: root.present ? root.percent : null })
    }
  }
}
