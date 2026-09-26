import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../bar/widgets/TrayModel.js" as TrayModel
import "../services/bluetooth/BluetoothModel.js" as BluetoothModel
import "../services/media/MediaModel.js" as MediaModel
import "../services/timezone/ZonesModel.js" as ZonesModel
import "../services/weather/PlacesModel.js" as PlacesModel
import "MenuModel.js" as Model

import "../../Ui" as Ui

Ui.Panel {
  id: menu

  required property var contextMenu

  readonly property var items: ({
    // search: too many rows to scan without it, so a context menu hands the
    // level to the launcher.
    "apps": { icon: "󰀻", label: "Apps", provider: "apps", search: true },
    "keybindings": { icon: "\u{F11C}", label: "Keybindings", provider: "binds", search: true },
    "tray": { icon: "󰘔", label: "Tray", provider: "tray" },
    "trigger": { icon: "󱓞", label: "Trigger" },
    "trigger.screenshot": { icon: "", label: "Screenshot (desktop)",
      action: () => menu.shell.recordingService.shoot("screen") },
    "trigger.screenshotWindow": { icon: "", label: "Screenshot (window)",
      action: () => menu.shell.recordingService.shoot("window") },
    "trigger.screenshotRegion": { icon: "", label: "Screenshot (region)",
      action: () => menu.shell.recordingService.screenshot() },
    "trigger.record": { icon: "󰑊", label: "Record screen", action: () => menu.shell.recording.open() },
    "trigger.pause": {
      icon: menu.shell.recordingService.paused ? "󰐊" : "󰏤",
      label: menu.shell.recordingService.paused ? "Resume recording" : "Pause recording",
      enabled: menu.shell.recordingService.recording,
      action: () => menu.shell.recordingService.togglePause()
    },
    "trigger.stop": { icon: "󰓛", label: "Stop recording", enabled: menu.shell.recordingService.busy,
      action: () => menu.shell.recordingService.stop() },
    "trigger.emoji": { icon: "", label: "Emoji", provider: "emoji", search: true },
    "trigger.color": { icon: "󰃉", label: "Color picker", action: () => menu.shell.systemService.pickColor() },
    "trigger.close": { icon: "󰅖", label: "Close window", action: () => Quickshell.execDetached(
      Ui.Compositor.closeWindow())
    },
    // One node per panel button, in bar order, each opening its panel first.
    "settings": { icon: "", label: "Settings" },
    "settings.media": { icon: menu.shell.media.icon, label: "Media" },
    "settings.media.panel": { icon: "󰕮", label: "Media panel", action: () => menu.shell.media.open() },
    "settings.media.playPause": { icon: "󰐎", label: "Play/Pause", enabled: menu.hasPlayer,
      action: () => menu.shell.media.service.runAction("playPause") },
    "settings.media.next": { icon: "󰒭", label: "Next", enabled: menu.hasPlayer,
      action: () => menu.shell.media.service.runAction("next") },
    "settings.media.previous": { icon: "󰒮", label: "Previous", enabled: menu.hasPlayer,
      action: () => menu.shell.media.service.runAction("previous") },
    "settings.media.player": { icon: "󰌳", label: "Player", provider: "players" },
    "settings.audio": { icon: menu.shell.audio.icon, label: "Audio" },
    "settings.audio.panel": { icon: "󰕮", label: "Audio panel", action: () => menu.shell.audio.open() },
    "settings.audio.mute": { icon: menu.checkbox(!menu.shell.audio.muted), label: "Sound",
      action: () => menu.shell.audio.toggleMute() },
    "settings.audio.micMute": {
      icon: menu.checkbox(!menu.shell.audio.micMuted),
      label: "Microphone",
      enabled: menu.shell.audio.sources.length > 0,
      action: () => menu.shell.audio.toggleMicMute()
    },
    "settings.audio.output": { icon: "󰓃", label: "Output", provider: "sinks" },
    "settings.display": { icon: "󰍹", label: "Display" },
    "settings.display.panel": { icon: "󰕮", label: "Display panel", action: () => menu.shell.display.open() },
    "settings.display.theme": { icon: "", label: "Theme" },
    "settings.display.theme.dark": { icon: menu.shell.dark ? "󰄬" : "", label: "Dark",
      action: () => menu.shell.setDark(true) },
    "settings.display.theme.light": { icon: menu.shell.dark ? "" : "󰄬", label: "Light",
      action: () => menu.shell.setDark(false) },
    "settings.display.nightlight": { icon: "󰆔", label: "Nightlight" },
    "settings.display.nightlight.off": { icon: menu.shell.nightlight.mode === "off" ? "󰄬" : "󰆔", label: "Off",
      action: () => menu.shell.nightlight.setMode("off") },
    "settings.display.nightlight.auto": { icon: menu.shell.nightlight.mode === "auto" ? "󰄬" : "󰆔", label: "Auto",
      action: () => menu.shell.nightlight.setMode("auto") },
    "settings.display.nightlight.on": { icon: menu.shell.nightlight.mode === "on" ? "󰄬" : "󰆔", label: "On",
      action: () => menu.shell.nightlight.setMode("on") },
    "settings.display.textSize": { icon: "󰛖", label: "Text size", provider: "textScales" },
    "settings.display.wallpaper": { icon: "", label: "Wallpaper (workspace)",
      action: () => menu.shell.background.open("workspace") },
    "settings.display.backdrop": { icon: "", label: "Wallpaper (backdrop)",
      action: () => menu.shell.background.open("backdrop") },
    "settings.bluetooth": { icon: menu.shell.bluetoothService.icon, label: "Bluetooth" },
    "settings.bluetooth.panel": { icon: "󰕮", label: "Bluetooth panel", action: () => menu.shell.bluetooth.open() },
    "settings.bluetooth.power": {
      icon: menu.checkbox(menu.shell.bluetoothService.powered),
      label: "Bluetooth",
      enabled: menu.shell.bluetoothService.available,
      action: () => menu.shell.bluetoothService.togglePower()
    },
    "settings.bluetooth.devices": { icon: "󰂱", label: "Devices", provider: "devices" },
    "settings.bluetooth.pair": { icon: "󰐕", label: "Pair new device…", enabled: menu.shell.bluetoothService.available,
      action: () => Quickshell.execDetached(["ghostty", "-e", "bluetui"]) },
    "settings.network": { icon: menu.shell.networkService.icon, label: "Network" },
    "settings.network.panel": { icon: "󰕮", label: "Network panel", action: () => menu.shell.network.open() },
    "settings.network.wifi": {
      icon: menu.checkbox(menu.shell.networkService.wifiEnabled),
      label: "Wi-Fi",
      enabled: menu.shell.networkService.wifiDevice !== null,
      action: () => menu.shell.networkService.toggleWifi()
    },
    // The scanner runs only while the panel is open.
    "settings.network.scan": {
      icon: "󰐷",
      label: "Scan",
      enabled: menu.shell.networkService.wifiEnabled,
      action: () => {
        menu.shell.network.open()
        menu.shell.networkService.scan()
      }
    },
    "settings.network.networks": { icon: "󰖩", label: "Wi-Fi networks", provider: "networks" },
    "settings.network.editor": { icon: "󰌘", label: "Connection settings…",
      action: () => Quickshell.execDetached(["nm-connection-editor"]) },
    "settings.power": { icon: menu.shell.batteryService.icon, label: "Power" },
    "settings.power.panel": { icon: "󰕮", label: "Power panel", action: () => menu.shell.battery.open() },
    "settings.power.profile": { icon: "󰓅", label: "Profile" },
    "settings.power.profile.saver": menu.profileItem("power-saver", "󰌪", "Saver"),
    "settings.power.profile.balanced": menu.profileItem("balanced", "󰊚", "Balanced"),
    "settings.power.profile.performance": menu.profileItem("performance", "󰓅", "Performance"),
    "settings.clipboard": { icon: "\u{F014C}", label: "Clipboard" },
    "settings.clipboard.panel": { icon: "󰕮", label: "Clipboard panel", action: () => menu.shell.clipboard.open() },
    "settings.clipboard.clear": { icon: "󰃢", label: "Clear history",
      action: () => menu.shell.clipboard.service.clear() },
    "settings.notifications": { icon: "󰂚", label: "Notifications" },
    "settings.notifications.panel": { icon: "󰕮", label: "Notifications panel",
      action: () => menu.shell.notifications.showHistory() },
    "settings.notifications.clear": { icon: "󰃢", label: "Clear",
      action: () => menu.shell.notifications.clearHistory() },
    "settings.notifications.dnd": {
      icon: menu.checkbox(!menu.shell.notifications.doNotDisturb),
      label: "Notifications",
      action: () => menu.shell.notifications.setDoNotDisturb(!menu.shell.notifications.doNotDisturb)
    },
    "settings.weather": { icon: menu.shell.weatherService.icon, label: "Weather" },
    "settings.weather.panel": { icon: "󰕮", label: "Weather panel", action: () => menu.shell.weather.open() },
    "settings.weather.refresh": { icon: "󰑐", label: "Refresh", action: () => menu.shell.weatherService.refresh() },
    "settings.weather.forecast": { icon: "󰖐", label: "Today on yr.no", action: () => menu.shell.weather.openForecast() },
    "settings.weather.location": { icon: "󰖐", label: "Location", provider: "places", search: true },
    "settings.calendar": { icon: "󰃭", label: "Calendar" },
    "settings.calendar.panel": { icon: "󰕮", label: "Calendar panel", action: () => menu.shell.calendar.open() },
    "settings.calendar.refresh": { icon: "󰑐", label: "Refresh", action: () => menu.shell.calendar.service.refresh() },
    "settings.clock": { icon: "󰅐", label: "Clock" },
    "settings.clock.panel": { icon: "󰕮", label: "Clock panel", action: () => menu.shell.timezone.open() },
    "settings.clock.timezone": { icon: "󰅐", label: "Timezone", provider: "zones", search: true },
    "settings.keyboard": { icon: "󰌌", label: "Keyboard layout" },
    "settings.keyboard.us": {
      icon: menu.shell.keyboard.index === 0 ? "󰄬" : "󰌌",
      label: "English (US)",
      action: () => menu.shell.keyboard.set(0)
    },
    "settings.keyboard.se": {
      icon: menu.shell.keyboard.index === 1 ? "󰄬" : "󰌌",
      label: "Swedish",
      action: () => menu.shell.keyboard.set(1)
    },
    "settings.session": { icon: "󰐥", label: "Session" },
    "settings.session.lock": { icon: "", label: "Lock", action: () => menu.shell.lock.beginLock() },
    "settings.session.screensaver": { icon: "󰛑", label: "Screensaver", action: () => menu.shell.screensaver.show() },
    "settings.session.idle": {
      icon: menu.checkbox(menu.shell.idle.enabled),
      label: "Idle locking",
      action: () => menu.shell.idle.setEnabled(!menu.shell.idle.enabled)
    },
    "settings.session.suspend": { icon: "󰒲", label: "Suspend", action: () => menu.run("systemctl suspend") },
    "settings.session.logout": { icon: "󰍃", label: "Logout", action: () => menu.run("uwsm stop") },
    "settings.session.reboot": { icon: "󰜉", label: "Reboot", action: () => menu.run("systemctl reboot") },
    "settings.session.shutdown": { icon: "󰐥", label: "Shutdown", action: () => menu.run("systemctl poweroff") },
  })

  readonly property bool hasPlayer: menu.shell.media.service.activePlayer !== null

  function checkbox(on) { return on ? "󰄲" : "󰄱" }

  function profileItem(name, icon, label) {
    const service = menu.shell.batteryService
    return {
      icon: service.profile === name ? "󰄬" : icon,
      label: label,
      enabled: service.profiles.indexOf(name) >= 0,
      action: () => service.setProfile(name),
    }
  }

  function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

  property string level: "root"

  cardWidth: wide ? 900 : 600
  cardHeight: wide ? 640 : 420

  property var binds: []

  FileView {
    id: bindsFile
    path: Ui.Compositor.configFile(Quickshell.env("HOME"))
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: menu.binds = Ui.Compositor.parseBinds(text())
  }

  property var emojis: []

  FileView {
    path: Quickshell.env("EMOJI_TEST") || ""
    printErrors: false
    onLoaded: menu.emojis = Model.parseEmoji(text()).map(e => ({
      label: e.name,
      icon: e.emoji,
      image: "",
      detail: "",
      enabled: true,
      entry: null,
      action: () => Quickshell.execDetached(["wl-copy", e.emoji]),
    }))
  }

  function iconUrl(icon) {
    const value = String(icon || "")
    if (value.length === 0) return ""
    if (value.startsWith("/")) return "file://" + value
    if (value.startsWith("file://") || value.startsWith("image://")) return value
    return Quickshell.iconPath(value, true)
  }

  function trayRows() {
    return TrayModel.sortItems(SystemTray.items.values)
      .map(item => ({
        label: TrayModel.labelFor(item),
        icon: "󰘔",
        image: TrayModel.themeIconName(item.icon) === ""
          ? (item.icon || "")
          : menu.iconUrl(TrayModel.themeIconName(item.icon)),
        detail: item.tooltipTitle && item.title !== item.tooltipTitle ? item.tooltipTitle : "",
        enabled: true,
        entry: null,
        trayItem: item,
      }))
  }

  // Built when entries load, not per keystroke: a first icon-theme lookup costs
  // ~25 ms per app.
  readonly property var apps: DesktopEntries.applications.values
    .filter(entry => !entry.noDisplay)
    .sort((a, b) => a.name.localeCompare(b.name))
    .map(entry => ({ label: entry.name, icon: "󰀻", image: menu.iconUrl(entry.icon), detail: "", enabled: true, entry: entry }))

  function appRows(detail) {
    return apps.map(row => Object.assign({}, row, { detail: detail || "" }))
  }

  function placeRows() {
    const service = menu.shell.weatherService
    return PlacesModel.places.map(place => ({
      label: place.name,
      icon: service.latitude === place.latitude && service.longitude === place.longitude ? "󰄬" : "󰖐",
      image: "",
      detail: place.country,
      enabled: true,
      entry: null,
      action: () => service.setLocation(place.latitude, place.longitude, place.name),
    }))
  }

  // Setting the zone goes through polkit, so the agent may ask before it lands.
  function zoneRows() {
    const service = menu.shell.timezoneService
    return ZonesModel.zones.map(zone => ({
      label: zone.name,
      icon: service.zone === zone.zone ? "󰄬" : "󰅐",
      image: "",
      detail: zone.zone,
      enabled: true,
      entry: null,
      action: () => service.setZone(zone.zone),
    }))
  }

  function playerRows() {
    const service = menu.shell.media.service
    const active = service.playerKey(service.activePlayer)
    return service.sourcePlayers.map(player => ({
      label: MediaModel.labelFor(player),
      icon: service.playerKey(player) === active ? "󰄬" : "󰌳",
      detail: MediaModel.detailFor(player),
      enabled: true,
      action: () => service.selectPlayer(service.playerKey(player)),
    }))
  }

  function sinkRows() {
    const audio = menu.shell.audio
    return audio.sinks.map(node => ({
      label: audio.label(node),
      icon: node === audio.sink ? "󰄬" : "󰓃",
      detail: "",
      enabled: true,
      action: () => audio.setDefault(node),
    }))
  }

  function textScaleRows() {
    return menu.shell.display.textScales.map(value => ({
      label: Math.round(value * 100) + "%",
      icon: Math.abs(value - menu.shell.textScale) < 0.01 ? "󰄬" : "󰛖",
      detail: "",
      enabled: true,
      action: () => menu.shell.setTextScale(value),
    }))
  }

  function deviceRows() {
    const service = menu.shell.bluetoothService
    return (service.powered ? service.devices : []).map(device => ({
      label: BluetoothModel.deviceName(device),
      icon: device.connected ? "󰄬" : service.deviceIcon(device),
      detail: service.deviceStatus(device),
      enabled: true,
      action: () => service.toggleConnection(device),
    }))
  }

  // Known networks only: the scanner runs while the Network panel is open.
  function networkRows() {
    const service = menu.shell.networkService
    return (service.wifiEnabled ? service.wifiNetworks : []).map(network => ({
      label: network.name,
      icon: network.connected ? "󰄬" : "󰖩",
      detail: service.wifiStatus(network),
      enabled: true,
      action: () => service.activate(network),
    }))
  }

  IpcHandler {
    target: "menu"

    function toggle(): void { menu.toggle() }
    function open(): void { menu.open("root") }
    function close(): void { menu.close() }
    function level(id: string): void { menu.open(id) }
    function popup(id: string): void { menu.popup(id, "", null) }
  }

  readonly property var providers: ({
    binds: function() { return menu.binds },
    tray: function() { return menu.trayRows() },
    apps: function(detail) { return menu.appRows(detail) },
    places: function() { return menu.placeRows() },
    zones: function() { return menu.zoneRows() },
    emoji: function() { return menu.emojis },
    players: function() { return menu.playerRows() },
    sinks: function() { return menu.sinkRows() },
    textScales: function() { return menu.textScaleRows() },
    devices: function() { return menu.deviceRows() },
    networks: function() { return menu.networkRows() },
  })

  readonly property var rows: Model.rowsFor(menu.items, level, input.text, menu.providers)

  // Launcher rows shaped like QsMenuEntry, for the context menu.
  function contextRows(target) {
    const rows = Model.rowsFor(menu.items, target, "", menu.providers).map(row => {
      const cascades = row.submenu && !menu.items[row.id].search
      const handsOff = row.submenu && !cascades
      const run = handsOff ? () => menu.open(row.id)
        : row.trayItem || row.entry || row.action ? () => menu.launch(row) : null
      return {
        text: row.label + (handsOff ? "…" : ""),
        glyph: row.icon,
        enabled: row.enabled && (cascades || !!run),
        isSeparator: false,
        hasChildren: cascades,
        rows: cascades ? () => menu.contextRows(row.id) : undefined,
        triggered: run,
        key: row.id,
      }
    })
    // The top level opens the launcher where a node opens its panel.
    if (target === "root") rows.unshift({ text: "Launcher", glyph: "\u{F056E}", enabled: true,
      isSeparator: false, hasChildren: false, triggered: () => menu.open("root"), key: "root.panel" })
    // Sets a node's panel row apart from its actions.
    if (rows[0]?.key === target + ".panel") rows.splice(1, 0, { isSeparator: true, enabled: true })
    return rows
  }

  property string popped: ""

  // Opens target as a context menu hanging from button on output; without them
  // it centers on the focused output. Opening the shown one again on its output
  // closes it.
  function popup(target, output, button) {
    if (contextMenu.shown && popped === target && (!output || contextMenu.screen?.name === output)) {
      contextMenu.close()
      return
    }
    popped = target
    contextMenu.popup({ rows: () => menu.contextRows(target) }, output, button ? () => {
      const point = button.mapToItem(null, 0, 0)
      return { below: true, x: point.x, width: button.width }
    } : null)
  }

  function selectFirstEnabled() {
    list.currentIndex = Model.selectFirstEnabled(rows)
  }

  function move(steps) {
    if (rows.length === 0) return
    list.currentIndex = Model.moveIndex(rows, list.currentIndex, steps)
  }

  readonly property string title: level === "root" ? "Go" : menu.items[level].label

  readonly property bool wide: level !== "root" && menu.items[level].provider === "binds"

  function open(target) {
    if (shell && shell.registerPanel) shell.registerPanel(menu)
    if (shell && shell.claimPanel) shell.claimPanel(menu)
    level = target
    input.text = ""
    shown = true
    input.forceActiveFocus()
    Qt.callLater(selectFirstEnabled)
  }

  function toggle() { shown ? close() : open("root") }

  function back() {
    if (level === "root") close()
    else open(Model.parentLevel(level))
  }

  function activate() {
    const row = rows[list.currentIndex]
    if (!row || !row.enabled) return

    if (row.trayItem || row.entry || row.action) {
      close()
      launch(row)
    } else if (row.id) {
      open(row.id)
    }
  }

  function launch(row) {
    if (row.trayItem) {
      if (row.trayItem.hasMenu) menu.shell.tray.openFor(row.trayItem)
      else row.trayItem.activate()
    } else if (row.entry) {
      // Keep launched apps out of Quickshell's service scope.
      Quickshell.execDetached(["uwsm-app", "--", row.entry.id + ".desktop"])
    } else {
      row.action()
    }
  }

  Text {
    color: menu.shell.palette.dim
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: menu.title
  }

  TextInput {
    id: input
    width: parent.width
    clip: true
    color: menu.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    focus: true

    // Keyed on the query, not on rows: the rows binding returns a fresh array
    // whenever any provider notifies, which would reset the selection mid-scroll.
    // ListView resets currentIndex after this handler runs.
    onTextChanged: Qt.callLater(menu.selectFirstEnabled)

    Text {
      anchors.fill: parent
      visible: input.text.length === 0
      color: menu.shell.palette.dim
      font: input.font
      text: "Search…"
    }

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) menu.back()
      else if (event.key === Qt.Key_Left && input.text.length === 0) menu.back()
      else if (event.key === Qt.Key_Down) menu.move(1)
      else if (event.key === Qt.Key_Up) menu.move(-1)
      else if (event.key === Qt.Key_PageDown) menu.move(10)
      else if (event.key === Qt.Key_PageUp) menu.move(-10)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) menu.activate()
      else if (event.key === Qt.Key_Right && input.text.length === 0) menu.activate()
      else return
      event.accepted = true
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: menu.shell.palette.dim
  }

  ListView {
    id: list
    width: parent.width
    height: parent.height - y
    clip: true
    model: menu.rows

    delegate: Rectangle {
      required property var modelData
      required property int index

      width: list.width
      height: 36
      color: index === list.currentIndex ? menu.shell.palette.sel : "transparent"
      radius: 4

      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 10

        Item {
          width: 20
          height: 20
          visible: modelData.chord === undefined

          Image {
            id: rowImage
            anchors.fill: parent
            source: modelData.image || ""
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            sourceSize.width: width * Screen.devicePixelRatio
            sourceSize.height: height * Screen.devicePixelRatio
          }

          Text {
            anchors.fill: parent
            visible: !rowImage.visible
            verticalAlignment: Text.AlignVCenter
            color: modelData.enabled ? menu.shell.palette.fg : menu.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 15
            text: modelData.icon || ""
          }
        }

        Text {
          width: 290
          visible: modelData.chord !== undefined
          color: menu.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 15
          text: modelData.chord || ""
        }

        Text {
          color: modelData.enabled ? menu.shell.palette.fg : menu.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 15
          width: modelData.detail ? Math.min(implicitWidth, 300) : implicitWidth
          text: modelData.label + (modelData.submenu ? " ›" : "")
          elide: Text.ElideRight
        }

        Text {
          visible: (modelData.detail || "") !== ""
          color: menu.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 15
          text: modelData.detail || ""
          elide: Text.ElideRight
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (!modelData.enabled) return
          list.currentIndex = index
          menu.activate()
        }
      }
    }
  }
}
