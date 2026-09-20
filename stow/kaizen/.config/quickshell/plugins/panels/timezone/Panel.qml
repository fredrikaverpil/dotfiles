import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/timezone/TimezoneModel.js" as Model

Ui.Panel {
  id: root

  required property var service

  cardWidth: 460
  cardHeight: 330
  keyNavigation: true

  readonly property var info: service.info
  readonly property var rows: [
    { label: "Zone", value: info.zone === "" ? "unknown" : info.zone },
    { label: "Date", value: info.weekday + " " + info.date },
    { label: "Offset", value: root.offsetText },
    { label: "UTC", value: info.utcTime + "   " + info.utcDate },
    { label: "DST", value: Model.dstLabel(info.dst) },
    { label: "Next", value: Model.nextLabel(info.dst) },
    { label: "NTP", value: info.synchronized ? "Synchronised" : "Not synchronised" },
  ]

  readonly property string offsetText: {
    const seconds = Model.offsetSeconds(info.offset)
    if (seconds === null) return "unknown"
    const abbreviation = Model.abbreviationLabel(info.abbreviation, info.offset)
    return (abbreviation === "" ? "" : abbreviation + "   ") + Model.offsetLabel(seconds)
  }

  // date(1) and zdump run only while this is on screen.
  Binding {
    target: root.service
    property: "polling"
    value: root.shown
  }

  IpcHandler {
    target: "timezone"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.service.refresh() }
    function set(zone: string): string { return root.service.setZone(zone) ? "ok" : "invalid" }
    function home(): void { root.service.resetZone() }
    function status(): string {
      return JSON.stringify({
        zone: root.info.zone,
        time: root.info.time,
        date: root.info.date,
        offset: root.info.offset,
        abbreviation: root.info.abbreviation,
        synchronized: root.info.synchronized,
        dst: Model.dstLabel(root.info.dst),
        next: Model.nextLabel(root.info.dst),
        error: root.service.lastError,
      })
    }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Clock"
  }

  Text {
    width: parent.width
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: "Pick a timezone from Go › Setup › Timezone"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 40
    text: root.info.time === "" ? "--:--:--" : root.info.time
  }

  Repeater {
    model: root.rows

    delegate: Row {
      id: fieldRow

      required property var modelData

      width: parent.width
      height: 20
      spacing: 10

      Text {
        width: 64
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: fieldRow.modelData.label
      }

      Text {
        width: parent.width - 74
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: fieldRow.modelData.value
      }
    }
  }

  // The bar clock comes from Qt, which resolves the zone once at startup, so a
  // change lands here before it lands there.
  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: Model.staleClock(root.info.offset, new Date().getTimezoneOffset())
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 12
    text: "󰀦 Bar clock is still on the previous zone. "
      + "Restart with: systemctl --user restart quickshell dcal"
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: text.length > 0
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 12
    text: root.service.lastError
  }
}
