import QtQuick
import Quickshell
import Quickshell.Io

import "SystemModel.js" as Model

Item {
  id: root

  // Samples, keeps history and lists top processes while true.
  property bool live: false
  // Samples every 10 s in the background to raise alerts.
  property bool monitoring: true
  property bool stateLoaded: false
  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-system-monitor.json"

  property var alertStarts: ({})
  property var alerts: []
  readonly property var alert: alerts.length > 0 ? alerts[0] : null

  property real cpu: 0
  property var cores: []
  property real temperature: NaN
  property var memory: Model.parseMemory("")
  property string load: ""
  property string networkInterface: ""
  property real rxRate: 0
  property real txRate: 0
  property var processes: []

  property var cpuHistory: []
  property var memoryHistory: []
  property var rxHistory: []
  property var txHistory: []

  property var cpuTimes: null
  property var netSample: null

  readonly property real memoryPercent: memory.total > 0
    ? (memory.total - memory.available) / memory.total * 100 : 0

  function record(values, value) {
    return values.concat([value]).slice(-Model.historyLength)
  }

  function sample() {
    stat.reload()
    meminfo.reload()
    loadavg.reload()
    route.reload()
    netdev.reload()
    if (temperatureFile.path !== "") temperatureFile.reload()
    if (live && !top.running) top.running = true
  }

  function updateCpu(text) {
    const times = Model.parseCpuTimes(text)
    const usage = Model.cpuUsage(cpuTimes, times)
    cpuTimes = times
    if (usage.length === 0) return
    cpu = usage[0]
    cores = usage.slice(1)
    if (live) cpuHistory = record(cpuHistory, cpu)
  }

  function updateMemory(text) {
    memory = Model.parseMemory(text)
    if (live) memoryHistory = record(memoryHistory, memoryPercent)
  }

  // An interface change restarts the rate instead of reading as a spike.
  function updateNetwork(text) {
    const bytes = Model.interfaceBytes(text, networkInterface)
    const next = bytes ? { name: networkInterface, time: Date.now(), rx: bytes.rx, tx: bytes.tx } : null
    const previous = netSample && next && netSample.name === next.name ? netSample : null
    const seconds = previous ? (next.time - previous.time) / 1000 : 0
    rxRate = previous ? Model.rate(previous.rx, next.rx, seconds) : 0
    txRate = previous ? Model.rate(previous.tx, next.tx, seconds) : 0
    netSample = next
    if (!live) return
    rxHistory = record(rxHistory, rxRate)
    txHistory = record(txHistory, txRate)
  }

  function evaluate() {
    if (!monitoring) return
    const now = Date.now()
    const met = Model.conditions({ cpu: cpu, memory: memory, temperature: temperature, txRate: txRate })
    alertStarts = Model.since(alertStarts, met, now)
    alerts = Model.sustained(alertStarts, now)
  }

  function setMonitoring(value) {
    monitoring = !!value
  }

  function saveState() {
    if (stateLoaded) stateFile.setText(JSON.stringify({ version: 1, monitoring: monitoring }) + "\n")
  }

  function status() {
    return JSON.stringify({
      live: live,
      monitoring: monitoring,
      alerts: alerts.map(alert => alert.kind),
      cpu: Math.round(cpu),
      cores: cores.length,
      temperature: isFinite(temperature) ? Math.round(temperature) : null,
      memory: Math.round(memoryPercent),
      interface: networkInterface,
      rx: Math.round(rxRate),
      tx: Math.round(txRate),
      load: load,
      processes: processes.length
    })
  }

  onLiveChanged: {
    if (!live) return
    // Old baselines would average over the whole time sampling was off.
    if (!monitoring) {
      cpuTimes = null
      netSample = null
    }
    cpuHistory = []
    memoryHistory = []
    rxHistory = []
    txHistory = []
    sample()
  }

  onMonitoringChanged: {
    saveState()
    if (monitoring) return
    alertStarts = ({})
    alerts = []
  }

  Component.onCompleted: {
    stateLoaded = true
    stateFile.reload()
  }

  // Alerts use the previous tick's values, loaded right after it.
  Timer {
    interval: root.live ? 2000 : 10000
    running: root.live || root.monitoring
    repeat: true
    onTriggered: {
      root.evaluate()
      root.sample()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        root.monitoring = JSON.parse(String(text() || "")).monitoring !== false
      } catch (error) {
        root.monitoring = true
      }
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
    onLoaded: root.updateMemory(text())
  }

  FileView {
    id: loadavg
    path: "/proc/loadavg"
    printErrors: false
    onLoaded: root.load = text().trim().split(/\s+/).slice(0, 3).join(" ")
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

  Process {
    id: top
    command: ["sh", "-c", "top -b -n 2 -d 1 -w 512 -o %CPU | awk '/^ *PID /{n++} n == 2 && k++ < 6'"]
    stdout: StdioCollector {
      onStreamFinished: root.processes = Model.parseTop(text, 5)
    }
  }
}
