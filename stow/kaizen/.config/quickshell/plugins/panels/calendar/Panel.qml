import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
  id: root

  required property var service

  cardWidth: 520
  cardHeight: 460
  keyNavigation: true

  onShownChanged: if (shown) service.refresh()

  function openEvent(event) {
    Quickshell.execDetached(["dcal", "ipc", "ui.openEvent", "uid=" + event.uid, "start=" + event.start])
    root.close()
  }

  function join(event) {
    Quickshell.execDetached(["xdg-open", event.meetingUrl])
    root.close()
  }

  readonly property var focusedItem: scroller.Window.activeFocusItem
  // Map to content coordinates: Flickable coordinates are relative to its viewport.
  onFocusedItemChanged: {
    const item = focusedItem
    if (!item || !shown) return
    const top = item.mapToItem(content, 0, 0).y
    if (!isFinite(top)) return
    if (top < scroller.contentY) scroller.contentY = Math.max(0, top)
    else if (top + item.height > scroller.contentY + scroller.height)
      scroller.contentY = top + item.height - scroller.height
  }

  IpcHandler {
    target: "calendar"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.service.refresh() }
    function status(): string {
      return JSON.stringify({
        failed: root.service.failed,
        days: root.service.days.length,
        events: root.service.days.reduce((count, day) => count + day.events.length, 0),
      })
    }
  }

  Text {
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Calendar"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Text {
    visible: root.service.failed
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: "dcal is not running"
  }

  Flickable {
    id: scroller
    width: parent.width
    height: parent.height - y
    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content
      width: scroller.width
      spacing: 10

      Repeater {
        model: root.service.days

        delegate: DaySection {}
      }
    }
  }

  component DaySection: Column {
    id: day

    required property var modelData
    required property int index

    width: parent.width
    spacing: 2

    Text {
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      font.bold: true
      text: (day.index < 2 ? ["Today", "Tomorrow"][day.index] + " · " : "")
        + Qt.formatDateTime(day.modelData.date, "dddd d MMMM")
    }

    Repeater {
      model: day.modelData.events

      delegate: EventRow {}
    }

    Text {
      visible: day.modelData.events.length === 0
      leftPadding: 8
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: "No events"
    }
  }

  component EventRow: Rectangle {
    id: row

    required property var modelData

    width: parent.width
    height: 30
    radius: 4
    color: activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
    activeFocusOnTab: true

    Keys.onReturnPressed: root.openEvent(row.modelData)
    Keys.onEnterPressed: root.openEvent(row.modelData)
    Keys.onSpacePressed: root.openEvent(row.modelData)

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.openEvent(row.modelData)
    }

    Text {
      id: tag
      anchors.left: parent.left
      anchors.leftMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      width: 24
      horizontalAlignment: Text.AlignHCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      font.bold: true
      text: row.modelData.tag
    }

    Text {
      id: time
      anchors.left: tag.right
      anchors.leftMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 104
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: row.modelData.time
    }

    Text {
      anchors.left: time.right
      anchors.right: joinButton.visible ? joinButton.left : parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: row.modelData.summary + (row.modelData.location ? "  · " + row.modelData.location : "")
    }

    Rectangle {
      id: joinButton
      visible: row.modelData.meetingUrl !== ""
      anchors.right: parent.right
      anchors.rightMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      width: 72
      height: 22
      radius: 4
      color: activeFocus || joinMouse.containsMouse ? root.shell.palette.sel : "transparent"
      border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
      border.width: 1
      activeFocusOnTab: visible

      Keys.onReturnPressed: root.join(row.modelData)
      Keys.onEnterPressed: root.join(row.modelData)
      Keys.onSpacePressed: root.join(row.modelData)

      Text {
        anchors.centerIn: parent
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 12
        text: "󰍫 Join"
      }

      MouseArea {
        id: joinMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.join(row.modelData)
      }
    }
  }
}
