import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../bar/widgets/TrayModel.js" as TrayModel
import "../services/timezone/ZonesModel.js" as ZonesModel
import "../services/weather/PlacesModel.js" as PlacesModel
import "MenuModel.js" as Model

import "../../Ui" as Ui

Ui.Panel {
  id: menu

  readonly property var items: ({
    "apps": { icon: "󰀻", label: "Apps", provider: "apps" },
    "keybindings": { icon: "", label: "Keybindings", provider: "binds" },
    "style": { icon: "", label: "Style" },
    "style.wallpaper": { icon: "", label: "Wallpaper (workspace)", action: () => menu.shell.background.open("workspace") },
    "style.backdrop": { icon: "", label: "Wallpaper (backdrop)", action: () => menu.shell.background.open("backdrop") },
    "style.theme": { icon: "", label: "Theme" },
    "style.theme.dark": { icon: "", label: "Dark", action: () => menu.shell.setDark(true) },
    "style.theme.light": { icon: "", label: "Light", action: () => menu.shell.setDark(false) },
    "trigger": { icon: "󱓞", label: "Trigger" },
    "trigger.screenshot": { icon: "", label: "Screenshot (desktop)",
      action: () => menu.shell.recordingService.shoot("screen") },
    "trigger.screenshotWindow": { icon: "", label: "Screenshot (window)",
      action: () => menu.shell.recordingService.shoot("window") },
    "trigger.screenshotRegion": { icon: "", label: "Screenshot (region)",
      action: () => menu.shell.recordingService.screenshot() },
    "trigger.record": { icon: "󰑊", label: "Record screen", action: () => menu.shell.recording.open() },
    "trigger.emoji": { icon: "", label: "Emoji", provider: "emoji" },
    "trigger.color": { icon: "󰃉", label: "Color picker", action: () => menu.shell.systemService.pickColor() },
    "trigger.clipboard": { icon: "\u{F014C}", label: "Clipboard", action: () => menu.shell.clipboard.open() },
    "panels": { icon: "󰕮", label: "Panels" },
    "panels.media": { icon: menu.shell.media.icon, label: "Media", action: () => menu.shell.media.open() },
    "panels.weather": { icon: menu.shell.weatherService.icon, label: "Weather", action: () => menu.shell.weather.open() },
    "panels.calendar": { icon: "󰃭", label: "Calendar", action: () => menu.shell.calendar.open() },
    "panels.clock": { icon: "󰅐", label: "Clock", action: () => menu.shell.timezone.open() },
    "tray": { icon: "󰘔", label: "Tray", provider: "tray" },
    "setup": { icon: "", label: "Setup" },
    "setup.display": { icon: "󰍹", label: "Display", action: () => menu.shell.display.open() },
    "setup.network": { icon: "󰈀", label: "Network", action: () => menu.shell.network.open() },
    "setup.bluetooth": { icon: "󰂯", label: "Bluetooth", action: () => menu.shell.bluetooth.open() },
    "setup.audio": { icon: "󰕾", label: "Audio", action: () => menu.shell.audio.open() },
    "setup.power": { icon: "󰂄", label: "Power", action: () => menu.shell.battery.open() },
    "setup.nightlight": { icon: "󰆔", label: "Nightlight", action: () => menu.shell.nightlight.toggle() },
    "setup.weather": { icon: menu.shell.weatherService.icon, label: "Weather location", provider: "places" },
    "setup.timezone": { icon: "󰅐", label: "Timezone", provider: "zones" },
    "setup.keyboard": { icon: "󰌌", label: "Keyboard layout" },
    "setup.keyboard.us": {
      icon: menu.shell.keyboard.index === 0 ? "󰄬" : "󰌌",
      label: "English (US)",
      action: () => menu.shell.keyboard.set(0)
    },
    "setup.keyboard.se": {
      icon: menu.shell.keyboard.index === 1 ? "󰄬" : "󰌌",
      label: "Swedish",
      action: () => menu.shell.keyboard.set(1)
    },
    "system": { icon: "", label: "System" },
    "system.close": { icon: "󰅖", label: "Close window", action: () => Quickshell.execDetached(
      Ui.Compositor.closeWindow())
    },
    "system.notifications": { icon: "󰂚", label: "Notifications" },
    "system.notifications.history": { icon: "󰎟", label: "History", action: () => menu.shell.notifications.showHistory() },
    "system.notifications.dnd": { icon: "󰂛", label: "Toggle Do Not Disturb", action: () => menu.shell.notifications.setDoNotDisturb(!menu.shell.notifications.doNotDisturb) },
    "system.lock": { icon: "", label: "Lock", action: () => menu.shell.lock.beginLock() },
    "system.screensaver": { icon: "󰛑", label: "Screensaver", action: () => menu.shell.screensaver.show() },
    "system.idle": {
      icon: menu.shell.idle.enabled ? "󰾪" : "󰅶",
      label: menu.shell.idle.enabled ? "Disable idle locking" : "Enable idle locking",
      action: () => menu.shell.idle.setEnabled(!menu.shell.idle.enabled)
    },
    "system.suspend": { icon: "󰒲", label: "Suspend", action: () => menu.run("systemctl suspend") },
    "system.logout": { icon: "󰍃", label: "Logout", action: () => menu.run("uwsm stop") },
    "system.reboot": { icon: "󰜉", label: "Reboot", action: () => menu.run("systemctl reboot") },
    "system.shutdown": { icon: "󰐥", label: "Shutdown", action: () => menu.run("systemctl poweroff") },
  })

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

  IpcHandler {
    target: "menu"

    function toggle(): void { menu.toggle() }
    function open(): void { menu.open("root") }
    function close(): void { menu.close() }
    function level(id: string): void { menu.open(id) }
  }

  readonly property var rows: Model.rowsFor(menu.items, level, input.text, {
    binds: function() { return menu.binds },
    tray: function() { return menu.trayRows() },
    apps: function(detail) { return menu.appRows(detail) },
    places: function() { return menu.placeRows() },
    zones: function() { return menu.zoneRows() },
    emoji: function() { return menu.emojis },
  })

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

  function toggleLevel(target) {
    if (shown && level === target) close()
    else open(target)
  }

  function back() {
    if (level === "root") close()
    else open(Model.parentLevel(level))
  }

  function activate() {
    const row = rows[list.currentIndex]
    if (!row || !row.enabled) return

    if (row.trayItem) {
      close()
      if (row.trayItem.hasMenu) menu.shell.tray.openFor(row.trayItem)
      else row.trayItem.activate()
    } else if (row.entry) {
      close()
      // Keep launched apps out of Quickshell's service scope.
      Quickshell.execDetached(["uwsm-app", "--", row.entry.id + ".desktop"])
    } else if (row.action) {
      close()
      row.action()
    } else if (row.id) {
      open(row.id)
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
