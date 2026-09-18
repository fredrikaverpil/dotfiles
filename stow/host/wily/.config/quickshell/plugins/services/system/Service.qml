import QtQuick
import Quickshell
import Quickshell.Io

import "SystemModel.js" as Model

// Samples every 10 s and raises alerts on sustained load.
Item {
  id: root

  property var alertStarts: ({})
  property var alerts: []
  readonly property var alert: alerts.length > 0 ? alerts[0] : null

  property real cpu: 0
  property real temperature: NaN
  property var memory: Model.parseMemory("")
  property string networkInterface: ""
  property real txRate: 0

  property var cpuTimes: null
  property var netSample: null

  readonly property real memoryPercent: memory.total > 0
    ? (memory.total - memory.available) / memory.total * 100 : 0

  function sample() {
    stat.reload()
    meminfo.reload()
    route.reload()
    netdev.reload()
    if (temperatureFile.path !== "") temperatureFile.reload()
  }

  function updateCpu(text) {
    const times = Model.parseCpuTimes(text)
    cpu = Model.cpuUsage(cpuTimes, times)
    cpuTimes = times
  }

  // An interface change restarts the rate instead of reading as a spike.
  function updateNetwork(text) {
    const bytes = Model.transmittedBytes(text, networkInterface)
    const next = bytes !== null ? { name: networkInterface, time: Date.now(), tx: bytes } : null
    const previous = netSample && next && netSample.name === next.name ? netSample : null
    txRate = previous ? Model.rate(previous.tx, next.tx, (next.time - previous.time) / 1000) : 0
    netSample = next
  }

  function evaluate() {
    const now = Date.now()
    const met = Model.conditions({ cpu: cpu, memory: memory, temperature: temperature, txRate: txRate })
    alertStarts = Model.since(alertStarts, met, now)
    alerts = Model.sustained(alertStarts, now)
  }

  function openMonitor() {
    Quickshell.execDetached(["uwsm-app", "--", "io.missioncenter.MissionCenter.desktop"])
  }

  Component.onCompleted: sample()

  // Alerts use the previous tick's values, loaded right after it.
  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: {
      root.evaluate()
      root.sample()
    }
  }

  IpcHandler {
    target: "system"

    function status(): string {
      return JSON.stringify({
        alerts: root.alerts.map(alert => alert.kind),
        cpu: Math.round(root.cpu),
        temperature: isFinite(root.temperature) ? Math.round(root.temperature) : null,
        memory: Math.round(root.memoryPercent),
        interface: root.networkInterface,
        tx: Math.round(root.txRate)
      })
    }
  }

  FileView {
    id: stat
    path: "/proc/stat"
    printErrors: false
    onLoaded: root.updateCpu(text())
  }

  FileView {
    id: meminfo
    path: "/proc/meminfo"
    printErrors: false
    onLoaded: root.memory = Model.parseMemory(text())
  }

  FileView {
    id: route
    path: "/proc/net/route"
    printErrors: false
    onLoaded: root.networkInterface = Model.defaultInterface(text())
  }

  FileView {
    id: netdev
    path: "/proc/net/dev"
    printErrors: false
    onLoaded: root.updateNetwork(text())
  }

  FileView {
    id: temperatureFile
    printErrors: false
    onLoaded: root.temperature = Number(text()) / 1000
  }

  // hwmon numbering changes between boots.
  Process {
    running: true
    command: ["sh", "-c", "grep -lx k10temp /sys/class/hwmon/hwmon*/name"]
    stdout: StdioCollector {
      onStreamFinished: {
        const name = text.trim().split("\n")[0]
        if (name !== "") temperatureFile.path = name.replace(/name$/, "temp1_input")
      }
    }
  }
}
