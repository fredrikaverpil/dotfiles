import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/weather/WeatherModel.js" as Model

Ui.Panel {
  id: root

  required property var service

  cardWidth: 420
  cardHeight: 350
  keyNavigation: true

  IpcHandler {
    target: "weather"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.service.refresh() }
    function setLocation(latitude: real, longitude: real, name: string): string {
      return root.service.setLocation(latitude, longitude, name) ? "ok" : "invalid"
    }
    function home(): void { root.service.resetLocation() }
    function status(): string {
      return JSON.stringify({
        place: root.service.place,
        latitude: root.service.latitude,
        longitude: root.service.longitude,
        temperature: root.service.temperature,
        condition: root.service.condition,
        days: root.service.days.length,
        pollMinutes: root.service.pollMinutes,
        updatedAt: root.service.updatedAt ? root.service.updatedAt.toISOString() : null,
      })
    }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Weather"
  }

  Text {
    width: parent.width
    elide: Text.ElideRight
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: (root.service.place === "" ? "Unknown location" : root.service.place)
      + (root.service.updatedAt
        ? "  ·  updated " + Qt.formatDateTime(root.service.updatedAt, "HH:mm:ss")
        : "")
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Row {
    width: parent.width
    height: 76
    spacing: 14

    Text {
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 46
      text: root.service.icon
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 34
      text: root.service.ready ? root.service.temperature : "--"
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Text {
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: root.service.failed ? "Unavailable" : root.service.condition
      }

      Text {
        visible: text.length > 0
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: root.service.wind === "" ? "" : "󰖝 " + root.service.wind + "   󰖎 " + root.service.humidity
      }
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Repeater {
    model: root.service.days

    delegate: Row {
      id: dayRow

      required property var modelData

      width: parent.width
      height: 26
      spacing: 10

      Text {
        width: 44
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: dayRow.modelData.name
      }

      Text {
        width: 24
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 16
        text: Model.icon(dayRow.modelData.symbol)
      }

      Text {
        width: 96
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: Model.temperature(dayRow.modelData.maximum) + " / " + Model.temperature(dayRow.modelData.minimum)
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: Model.condition(dayRow.modelData.symbol)
      }
    }
  }

  Item {
    width: parent.width
    height: 4
  }

  Rectangle {
    id: refreshButton
    width: parent.width
    height: 28
    radius: 4
    color: activeFocus ? root.shell.palette.sel : "transparent"
    border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    activeFocusOnTab: true

    Keys.onReturnPressed: root.service.refresh()
    Keys.onEnterPressed: root.service.refresh()
    Keys.onSpacePressed: root.service.refresh()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: root.service.busy ? "󰑐 Refreshing…" : "󰑐 Refresh"
    }

    MouseArea {
      anchors.fill: parent
      enabled: !root.service.busy
      onClicked: root.service.refresh()
    }
  }

  // CC BY 4.0 requires crediting MET Norway wherever their data is shown.
  Text {
    width: parent.width
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 11
    text: "Data from MET Norway (yr.no), CC BY 4.0"
  }
}
