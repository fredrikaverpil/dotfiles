import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

import "BatteryModel.js" as Model

Item {
  id: root

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/wily-power-profiles.json"
  readonly property int lowLevel: 10
  readonly property int criticalLevel: 5

  readonly property var deviceStates: ({
    Charging: UPowerDeviceState.Charging,
    FullyCharged: UPowerDeviceState.FullyCharged,
    PendingCharge: UPowerDeviceState.PendingCharge
  })

  readonly property var device: UPower.displayDevice
  // displayDevice is an aggregate without a sysfs path or health.
  readonly property var cell: UPower.devices.values.find(dev => dev.isLaptopBattery) || null
  readonly property bool present: !!device && device.isPresent
  readonly property bool onBattery: UPower.onBattery
  // Not named `battery`: that would make `onBattery` its signal handler.
  readonly property var snapshot: ({
    state: present ? device.state : UPowerDeviceState.Unknown,
    fraction: present ? device.percentage : 0,
    rate: present ? device.changeRate : 0,
    onBattery: onBattery,
    timeToEmpty: present ? device.timeToEmpty : 0,
    timeToFull: present ? device.timeToFull : 0
  })

  readonly property int percentage: Model.percent(snapshot.fraction)
  readonly property string stateLabel: Model.status(snapshot, deviceStates, endThreshold)
  readonly property string icon: Model.icon(snapshot, deviceStates, endThreshold)
  readonly property string timeRemaining: Model.timeRemaining(snapshot, deviceStates, endThreshold)
  readonly property string rate: present ? Model.formatRate(device.changeRate) : "--"
  readonly property string energy: present ? Model.formatEnergy(device.energy, device.energyCapacity) : "--"
  readonly property string health: cell ? Model.formatHealth(cell.healthSupported, cell.healthPercentage) : "--"

  property int startThreshold: 0
  property int endThreshold: 0
  property int cycles: 0
  readonly property string threshold: Model.formatThreshold(startThreshold, endThreshold)

  readonly property var profileValues: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
  readonly property var profiles: PowerProfiles.hasPerformanceProfile ? Model.profiles : Model.profiles.slice(0, 2)
  readonly property string profile: Model.profiles[profileValues.indexOf(PowerProfiles.profile)] || ""
  readonly property string source: onBattery ? "battery" : "ac"

  property bool stateLoaded: false
  property var savedProfiles: ({ ac: "", battery: "" })

  function refresh() {
    if (cell && !sysfs.running) sysfs.running = true
  }

  function applyProfile(name) {
    if (profiles.indexOf(name) < 0) return false
    PowerProfiles.profile = profileValues[Model.profiles.indexOf(name)]
    return true
  }

  // Remembered per power source; the low-battery power saver is not.
  function setProfile(name) {
    if (!applyProfile(name)) return false
    savedProfiles = Model.withProfile(savedProfiles, source, name)
    if (stateLoaded) stateFile.setText(Model.profilesText(savedProfiles))
    return true
  }

  function restoreProfile() {
    if (stateLoaded && present) applyProfile(Model.profileFor(savedProfiles, source, profiles))
  }

  function checkLevel() {
    const next = Model.lowBattery(percentage, present && onBattery, persisted.notified, lowLevel, criticalLevel)
    persisted.notified = next.notified
    if (next.notify === "") return
    applyProfile("power-saver")
    const critical = next.notify === "critical"
    Quickshell.execDetached(["notify-send", "-a", "Battery", "-i", "battery-caution",
      "-u", critical ? "critical" : "normal",
      critical ? "Battery critical" : "Battery low",
      percentage + "% remaining, switched to power saver"])
  }

  function status() {
    return JSON.stringify({
      present: present,
      percentage: percentage,
      state: stateLabel,
      onBattery: onBattery,
      profile: profile,
      profiles: profiles,
      threshold: { start: startThreshold, end: endThreshold }
    })
  }

  onPresentChanged: {
    refresh()
    restoreProfile()
    checkLevel()
  }
  onOnBatteryChanged: {
    restoreProfile()
    checkLevel()
  }
  onPercentageChanged: checkLevel()
  // Deferred until sysfs.workingDirectory follows the new cell.
  onCellChanged: Qt.callLater(refresh)

  Component.onCompleted: stateFile.reload()

  Connections {
    target: PowerProfiles
    function onHasPerformanceProfileChanged() { root.restoreProfile() }
  }

  // Keeps a hot reload from repeating a delivered warning.
  PersistentProperties {
    id: persisted
    reloadableId: "battery"
    property string notified: ""
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.savedProfiles = Model.loadedProfiles(text())
      root.stateLoaded = true
      root.restoreProfile()
    }
    onLoadFailed: {
      root.stateLoaded = true
      root.restoreProfile()
    }
  }

  Process {
    id: sysfs
    workingDirectory: root.cell ? "/sys/class/power_supply/" + root.cell.nativePath : ""
    command: ["grep", "-sH", ".", "charge_control_start_threshold", "charge_control_end_threshold", "cycle_count"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const values = Model.parseSysfs(text)
        root.startThreshold = values.start
        root.endThreshold = values.end
        root.cycles = values.cycles
      }
    }
  }
}
