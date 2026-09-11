import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
  id: root

  required property var service

  cardHeight: 420
  keyNavigation: true

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
    target: "bluetooth"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.service.status() }
  }

  Flickable {
    id: scroller
    width: parent.width
    height: parent.height
    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content
      width: scroller.width
      spacing: 10

      Row {
        width: parent.width
        spacing: 8

        Text {
          width: parent.width - (powerToggle.visible ? powerToggle.width + parent.spacing : 0)
          color: root.shell.palette.fg
          font.family: Ui.Fonts.mono
          font.pixelSize: 18
          text: "Bluetooth"
        }

        ActionButton {
          id: powerToggle
          visible: root.service.available
          width: 92
          label: root.service.powered ? "On" : "Off"
          active: root.service.powered
          onActivated: root.service.togglePower()
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Section {
        title: "Paired devices"

        Repeater {
          model: root.service.powered ? root.service.devices : []

          delegate: DeviceRow {
            required property var modelData
            device: modelData
          }
        }

        Text {
          width: parent.width
          visible: !root.service.powered || root.service.devices.length === 0
          color: root.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 13
          text: !root.service.available
            ? "No Bluetooth adapter"
            : !root.service.powered ? "Bluetooth is off" : "No paired devices"
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      ActionButton {
        visible: root.service.available
        width: 160
        label: "Pair new device…"
        onActivated: {
          root.close()
          Quickshell.execDetached(["ghostty", "-e", "bluetui"])
        }
      }
    }
  }

  component Section: Column {
    required property string title

    width: parent.width
    spacing: 6

    Text {
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: parent.title
    }
  }

  component ActionButton: Rectangle {
    id: button

    property string label: ""
    property bool active: false
    property bool available: true
    signal activated

    height: 28
    radius: 4
    color: active ? root.shell.palette.sel : "transparent"
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    opacity: available ? 1 : 0.45

    // Availability changes during connection changes; visibility alone controls focus membership.
    activeFocusOnTab: button.visible
    Keys.onReturnPressed: if (button.available) button.activated()
    Keys.onEnterPressed: if (button.available) button.activated()
    Keys.onSpacePressed: if (button.available) button.activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: button.label
    }

    MouseArea {
      anchors.fill: parent
      enabled: button.available
      hoverEnabled: true
      onClicked: button.activated()
    }
  }

  component DeviceRow: Rectangle {
    id: row

    required property var device
    readonly property string action: root.service.deviceAction(device)

    width: parent.width
    height: 42
    radius: 4
    color: device.connected ? root.shell.palette.sel : "transparent"
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 16
      text: root.service.deviceIcon(row.device)
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 34
      anchors.right: toggle.left
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: (row.device.name || row.device.address) + " · " + root.service.deviceStatus(row.device)
      elide: Text.ElideRight
    }

    // Keeps its width and focus while connecting; the label empties instead.
    ActionButton {
      id: toggle
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 96
      label: row.action || "…"
      available: row.action !== ""
      onActivated: root.service.toggleConnection(row.device)
    }
  }
}
