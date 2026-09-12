import QtQuick
import Quickshell
import Quickshell.Io

import "ShellModel.js" as Model

import "plugins/background" as Background
import "plugins/bar" as Bar
import "plugins/lock" as Lock
import "plugins/menu" as Menu
import "plugins/notifications" as Notifications
import "plugins/panels/audio" as Audio
import "plugins/panels/battery" as Battery
import "plugins/panels/bluetooth" as Bluetooth
import "plugins/panels/media" as Media
import "plugins/panels/monitor" as Monitor
import "plugins/panels/network" as Network
import "plugins/panels/recording" as Recording
import "plugins/panels/tray" as Tray
import "plugins/panels/weather" as Weather
import "plugins/polkit" as Polkit
import "plugins/services/battery" as BatteryService
import "plugins/services/bluetooth" as BluetoothService
import "plugins/services/brightness" as Brightness
import "plugins/services/idle" as Idle
import "plugins/services/keyboard" as Keyboard
import "plugins/services/media" as MediaService
import "plugins/services/network" as NetworkService
import "plugins/services/nightlight" as Nightlight
import "plugins/services/recording" as RecordingService
import "plugins/services/weather" as WeatherService
import "Ui" as Ui

ShellRoot {
  id: root

  readonly property alias menu: menu
  readonly property alias background: background
  readonly property alias notifications: notifications
  readonly property alias nightlight: nightlight
  readonly property alias idle: idle
  readonly property alias keyboard: keyboard
  readonly property alias media: media
  readonly property alias display: display
  readonly property alias brightness: brightness
  readonly property alias network: network
  readonly property alias networkService: networkService
  readonly property alias bluetooth: bluetooth
  readonly property alias bluetoothService: bluetoothService
  readonly property alias audio: audio
  readonly property alias battery: battery
  readonly property alias batteryService: batteryService
  readonly property alias tray: tray
  readonly property alias recording: recording
  readonly property alias recordingService: recordingService
  readonly property alias weather: weather
  readonly property alias weatherService: weatherService

  readonly property int barHeight: 32
  property var panels: []

  function registerPanel(panel) {
    if (panel && panels.indexOf(panel) < 0) panels = panels.concat([panel])
  }

  function claimPanel(panel) {
    for (const candidate of panels) {
      if (candidate && candidate !== panel && candidate.shown) candidate.close()
    }
  }

  property bool dark: true
  property real textScale: 1
  readonly property var darkPalette: ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })
  readonly property var lightPalette: ({ bg: "#F0EDEC", fg: "#2C363C", sel: "#CBD9E3", dim: "#CFC1BA", off: "#8F857D" })
  readonly property var palette: dark ? darkPalette : lightPalette

  // KConfig needs --notify before the dconf palette change or running Dolphin keeps cached view colours.
  function kdeglobalsWrite(on) { return Model.kdeglobalsWrite(on, darkPalette, lightPalette) }

  function writeKdeglobals() {
    kdeglobals.command = ["sh", "-c", kdeglobalsWrite(root.dark)]
    kdeglobals.running = true
  }

  function setDark(on) {
    const scheme = on ? "prefer-dark" : "prefer-light"
    const gtk = on ? "Adwaita-dark" : "Adwaita"
    write.command = ["sh", "-c",
      kdeglobalsWrite(on) +
      "dconf write /org/gnome/desktop/interface/color-scheme \"'" + scheme + "'\"; " +
      "dconf write /org/gnome/desktop/interface/gtk-theme \"'" + gtk + "'\""]
    write.running = true
  }

  // GNU sed otherwise replaces the Stow link rather than its target.
  function writeCompositorTheme() {
    // `palette` still holds the previous theme while this handler runs.
    const edits = Ui.Compositor.themeEdits(dark ? darkPalette : lightPalette)
    if (edits.length === 0) return
    compositorTheme.command = ["sed", "-i", "--follow-symlinks", "-E"]
      .concat(edits)
      .concat([Ui.Compositor.themeConfig])
    compositorTheme.running = true
  }

  onDarkChanged: {
    writeKdeglobals()
    writeCompositorTheme()
  }

  Process { id: write }
  Process { id: kdeglobals }
  Process { id: compositorTheme }

  function setTextScale(value) {
    const scale = Model.textScale(value)
    if (scale === null) return
    textScale = scale
    textScaleWrite.command = [
      "dconf",
      "write",
      "/org/gnome/desktop/interface/text-scaling-factor",
      String(scale),
    ]
    textScaleWrite.running = true
  }

  function updateTextScale(value) {
    const scale = Model.observedTextScale(value)
    if (scale !== null) textScale = scale
  }

  Process { id: textScaleWrite }

  IpcHandler {
    target: "theme"

    function toggle(): void { root.setDark(!root.dark) }
    function dark(): void { root.setDark(true) }
    function light(): void { root.setDark(false) }
  }

  Process {
    running: true
    command: ["dconf", "watch", "/org/gnome/desktop/interface/"]
    stdout: SplitParser {
      onRead: line => {
        if (line.indexOf("prefer-dark") >= 0) root.dark = true
        else if (line.indexOf("prefer-light") >= 0) root.dark = false
      }
    }
  }

  Process {
    running: true
    command: ["dconf", "read", "/org/gnome/desktop/interface/color-scheme"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.dark = text.indexOf("prefer-light") < 0
        root.writeKdeglobals()
        root.writeCompositorTheme()
      }
    }
  }

  Process {
    running: true
    command: ["dconf", "watch", "/org/gnome/desktop/interface/text-scaling-factor"]
    stdout: SplitParser {
      onRead: line => root.updateTextScale(line)
    }
  }

  Process {
    running: true
    command: ["dconf", "read", "/org/gnome/desktop/interface/text-scaling-factor"]
    stdout: StdioCollector {
      onStreamFinished: root.updateTextScale(text)
    }
  }

  readonly property var menuItems: ({
    "apps": { icon: "󰀻", label: "Apps", provider: "apps" },
    "learn": { icon: "󰧑", label: "Learn" },
    "learn.keybindings": { icon: "", label: "Keybindings", provider: "binds" },
    "learn.compositor": { icon: "", label: Ui.Compositor.name, enabled: false },
    "learn.nixos": { icon: "", label: "NixOS", enabled: false },
    "style": { icon: "", label: "Style" },
    "style.wallpaper": { icon: "", label: "Wallpaper", action: () => background.open() },
    "style.theme": { icon: "", label: "Theme" },
    "style.theme.dark": { icon: "", label: "Dark", action: () => root.setDark(true) },
    "style.theme.light": { icon: "", label: "Light", action: () => root.setDark(false) },
    "trigger": { icon: "󱓞", label: "Trigger" },
    "trigger.screenshot": { icon: "", label: "Screenshot (desktop)",
      action: () => Quickshell.execDetached(Ui.Compositor.screenshot("screen")) },
    "trigger.screenshotWindow": { icon: "", label: "Screenshot (window)",
      action: () => Quickshell.execDetached(Ui.Compositor.screenshot("window")) },
    "trigger.record": { icon: "󰑊", label: "Record screen", action: () => recording.open() },
    "trigger.emoji": { icon: "", label: "Emoji", enabled: false },
    "trigger.color": { icon: "󰃉", label: "Color picker", enabled: false },
    "trigger.share": { icon: "", label: "Share", enabled: false },
    "media": { icon: media.icon, label: "Media", action: () => media.open() },
    "weather": { icon: weatherService.icon, label: "Weather", action: () => weather.open() },
    "tray": { icon: "󰘔", label: "Tray", provider: "tray" },
    "setup": { icon: "", label: "Setup" },
    "setup.display": { icon: "󰍹", label: "Display", action: () => display.open() },
    "setup.network": { icon: "󰈀", label: "Network", action: () => network.open() },
    "setup.bluetooth": { icon: "󰂯", label: "Bluetooth", action: () => bluetooth.open() },
    "setup.audio": { icon: "󰕾", label: "Audio", action: () => audio.open() },
    "setup.power": { icon: "󰂄", label: "Power", action: () => battery.open() },
    "setup.nightlight": { icon: "󰆔", label: "Nightlight", action: () => nightlight.toggle() },
    "setup.weather": { icon: weatherService.icon, label: "Weather location", provider: "places" },
    "setup.keyboard": { icon: "󰌌", label: "Keyboard layout" },
    "setup.keyboard.us": {
      icon: keyboard.index === 0 ? "󰄬" : "󰌌",
      label: "English (US)",
      action: () => keyboard.set(0)
    },
    "setup.keyboard.se": {
      icon: keyboard.index === 1 ? "󰄬" : "󰌌",
      label: "Swedish",
      action: () => keyboard.set(1)
    },
    "system": { icon: "", label: "System" },
    "system.close": { icon: "󰅖", label: "Close window", action: () => Quickshell.execDetached(
      Ui.Compositor.closeWindow())
    },
    "system.notifications": { icon: "󰂚", label: "Notifications" },
    "system.notifications.history": { icon: "󰎟", label: "History", action: () => notifications.showHistory() },
    "system.notifications.dnd": { icon: "󰂛", label: "Toggle Do Not Disturb", action: () => notifications.setDoNotDisturb(!notifications.doNotDisturb) },
    "system.lock": { icon: "", label: "Lock", action: () => lock.beginLock() },
    "system.idle": {
      icon: idle.enabled ? "󰾪" : "󰅶",
      label: idle.enabled ? "Disable idle locking" : "Enable idle locking",
      action: () => idle.setEnabled(!idle.enabled)
    },
    "system.suspend": { icon: "󰒲", label: "Suspend", action: () => root.run("systemctl suspend") },
    "system.logout": { icon: "󰍃", label: "Logout", action: () => root.run("uwsm stop") },
    "system.reboot": { icon: "󰜉", label: "Reboot", action: () => root.run("systemctl reboot") },
    "system.shutdown": { icon: "󰐥", label: "Shutdown", action: () => root.run("systemctl poweroff") },
  })

  function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

  Notifications.Service {
    id: notifications
    shell: root
  }

  Lock.Service {
    id: lock
    shell: root
  }

  Idle.Service {
    id: idle
    lockService: lock
  }

  Keyboard.Service {
    id: keyboard
  }

  Nightlight.Service {
    id: nightlight
    shell: root
  }

  MediaService.Service {
    id: mediaService
  }

  Polkit.PolkitAgent {
    id: polkit
    shell: root
  }

  Background.Background {
    id: background
    shell: root
  }

  Media.Panel {
    id: media
    shell: root
    service: mediaService
  }

  Brightness.Service {
    id: brightness
  }

  Monitor.Panel {
    id: display
    shell: root
  }

  BatteryService.Service {
    id: batteryService
  }

  Battery.Panel {
    id: battery
    shell: root
    service: batteryService
  }

  NetworkService.Service {
    id: networkService
  }

  Network.Panel {
    id: network
    shell: root
    service: networkService
  }

  BluetoothService.Service {
    id: bluetoothService
  }

  Bluetooth.Panel {
    id: bluetooth
    shell: root
    service: bluetoothService
  }

  Audio.Panel {
    id: audio
    shell: root
  }

  Tray.Panel {
    id: tray
    shell: root
  }

  RecordingService.Service {
    id: recordingService
  }

  Recording.Panel {
    id: recording
    shell: root
    service: recordingService
  }

  Recording.Countdown {
    shell: root
    service: recordingService
  }

  WeatherService.Service {
    id: weatherService
  }

  Weather.Panel {
    id: weather
    shell: root
    service: weatherService
  }

  Menu.Menu {
    id: menu
    shell: root
    items: root.menuItems
  }

  Bar.Bar {
    shell: root
  }
}
