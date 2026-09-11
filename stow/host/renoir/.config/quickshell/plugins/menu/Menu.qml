import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../bar/widgets/TrayModel.js" as TrayModel
import "../services/weather/PlacesModel.js" as PlacesModel
import "MenuModel.js" as Model

import "../../Ui" as Ui

Ui.Panel {
  id: menu

  required property var items

  property string level: "root"

  cardWidth: wide ? 900 : 600
  cardHeight: wide ? 640 : 420

  property var binds: []

  FileView {
    id: bindsFile
    path: Quickshell.env("HOME") + "/.local/state/wm-binds.tsv"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: menu.binds = Model.parseBinds(text())
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

  function appRows(detail) {
    return DesktopEntries.applications.values
      .filter(entry => !entry.noDisplay)
      .sort((a, b) => a.name.localeCompare(b.name))
      .map(entry => ({ label: entry.name, icon: "󰀻", image: menu.iconUrl(entry.icon), detail: detail || "", enabled: true, entry: entry }))
  }

  function placeRows() {
    const service = menu.shell.weatherService
    return PlacesModel.places.map(place => ({
      label: place.name,
      icon: service.place === place.name ? "󰄬" : "󰖐",
      image: "",
      detail: place.country,
      enabled: true,
      entry: null,
      action: () => service.setLocation(place.latitude, place.longitude, place.name),
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
  })

  // ListView resets currentIndex after this handler runs.
  onRowsChanged: Qt.callLater(selectFirstEnabled)

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
      if (row.trayItem.onlyMenu) menu.shell.tray.openFor(row.trayItem)
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
