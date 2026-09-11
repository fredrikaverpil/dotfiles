import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
  id: root

  required property var service

  readonly property var profileLabels: ({
    "power-saver": "󰌪 Saver",
    "balanced": "󰊚 Balanced",
    "performance": "󰓅 Performance"
  })

  cardWidth: 480
  cardHeight: 262
  keyNavigation: true

  onShownChanged: if (shown) service.refresh()

  IpcHandler {
    target: "battery"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.service.status() }
    function setProfile(name: string): string { return root.service.setProfile(name) ? name : "unavailable" }
  }

  Row {
    width: parent.width

    Text {
      width: parent.width - percentLabel.width
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 18
      text: root.service.present ? root.service.icon + " Battery" : "Battery"
    }

    Text {
      id: percentLabel
      visible: root.service.present
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 18
      text: root.service.percentage + "%"
    }
  }

  Text {
    width: parent.width
    elide: Text.ElideRight
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: {
      if (!root.service.present) return "No battery reported by UPower"
      if (root.service.stateLabel === "Holding") return "Holding at " + root.service.threshold
      const time = root.service.timeRemaining
      if (time === "") return root.service.stateLabel
      return root.service.stateLabel + " · " + time + (root.service.onBattery ? " left" : " to full")
    }
  }

  Rectangle {
    visible: root.service.present
    width: parent.width
    height: 6
    radius: 3
    color: root.shell.palette.dim

    Rectangle {
      width: parent.width * root.service.percentage / 100
      height: parent.height
      radius: parent.radius
      color: root.shell.palette.fg
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  GridLayout {
    visible: root.service.present
    width: parent.width
    columns: 4
    columnSpacing: 14
    rowSpacing: 5

    MetricLabel { text: root.service.onBattery ? "Draining" : "Charging" }
    MetricValue { text: root.service.rate }
    MetricLabel { text: "Energy" }
    MetricValue { text: root.service.energy }

    MetricLabel { text: "Health" }
    MetricValue { text: root.service.health }
    MetricLabel { text: "Cycles" }
    MetricValue { text: root.service.cycles > 0 ? String(root.service.cycles) : "--" }

    MetricLabel { text: "Charge limit" }
    MetricValue { text: root.service.threshold }
    MetricLabel { text: "Power" }
    MetricValue { text: root.service.onBattery ? "Battery" : "AC" }
  }

  Rectangle {
    visible: root.service.present
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Text {
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 13
    text: "Power profile · " + (root.service.onBattery ? "on battery" : "on AC")
  }

  Row {
    id: profileRow
    width: parent.width
    spacing: 6

    Repeater {
      model: root.service.profiles

      delegate: ActionButton {
        required property string modelData
        width: (profileRow.width - profileRow.spacing * 2) / 3
        label: root.profileLabels[modelData] || modelData
        active: root.service.profile === modelData
        onActivated: root.service.setProfile(modelData)
      }
    }
  }

  component MetricLabel: Text {
    Layout.fillWidth: true
    color: root.shell.palette.off
    font.family: Ui.Fonts.mono
    font.pixelSize: 12
  }

  component MetricValue: Text {
    Layout.fillWidth: true
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 12
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideLeft
  }

  component ActionButton: Rectangle {
    id: button

    property string label: ""
    property bool active: false
    signal activated

    height: 28
    radius: 4
    color: active ? root.shell.palette.sel : "transparent"
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1

    activeFocusOnTab: button.visible
    Keys.onReturnPressed: button.activated()
    Keys.onEnterPressed: button.activated()
    Keys.onSpacePressed: button.activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: button.label
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.activated()
    }
  }
}
