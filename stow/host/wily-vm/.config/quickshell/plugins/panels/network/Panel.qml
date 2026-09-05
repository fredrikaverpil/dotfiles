import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/network/NetworkModel.js" as Model

// The view over plugins/services/network. Everything that talks to
// NetworkManager or spawns a process lives in that service; this file lays it
// out and takes the keyboard. Keep the panel deliberately smaller than
// Omarchy's counterpart: the remaining extras wait for real hardware before
// deciding which of their scripts are worth porting.
Ui.Panel {
  id: root

  required property var service

  cardHeight: 560
  keyNavigation: true

  // The metrics the service polls for are only on screen while the panel is.
  Binding {
    target: root.service
    property: "active"
    value: root.shown
  }

  // The Wi-Fi list outgrows the card, and Qt does not scroll a Flickable to
  // follow the focus chain. Map to `content`, not to the Flickable: the latter
  // yields viewport coordinates, which compare against contentY almost but not
  // quite correctly.
  readonly property var focusedItem: scroller.Window.activeFocusItem
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
    target: "network"

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
          width: parent.width - (wifiToggle.visible ? wifiToggle.width + parent.spacing : 0)
          color: root.shell.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
          text: "Network"
        }

        ActionButton {
          id: wifiToggle
          visible: root.service.wifiDevice !== null
          width: 92
          label: root.service.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
          active: root.service.wifiEnabled
          onActivated: root.service.toggleWifi()
        }
      }

      Text {
        width: parent.width
        visible: !root.service.networkManagerAvailable
        color: root.shell.palette.off
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: "NetworkManager is unavailable"
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Section {
        title: "Devices"

        Repeater {
          model: root.service.networkDevices

          delegate: DeviceRow {
            required property var modelData
            device: modelData
          }
        }

        Text {
          width: parent.width
          visible: root.service.networkDevices.length === 0
          color: root.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: "No network devices"
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Section {
        visible: root.service.hasConnection
        title: "Connection · " + root.service.connection.iface

        GridLayout {
          width: parent.width
          columns: 4
          columnSpacing: 14
          rowSpacing: 5

          MetricLabel { text: "Ping" }
          MetricValue { text: Model.formatPing(root.service.ping.latency, root.service.hasPing) }
          MetricLabel { text: "Packet loss" }
          MetricValue { text: Model.formatPacketLoss(root.service.ping.packetLoss, root.service.hasPing) }

          MetricLabel { text: "Receiving" }
          MetricValue { text: root.service.hasTransfer ? Model.formatRate(root.service.transfer.receivingRate) : "--" }
          MetricLabel { text: "Sending" }
          MetricValue { text: root.service.hasTransfer ? Model.formatRate(root.service.transfer.sendingRate) : "--" }

          MetricLabel { text: "Downloaded" }
          MetricValue { text: Model.formatBytes(root.service.connection.rxBytes) }
          MetricLabel { text: "Uploaded" }
          MetricValue { text: Model.formatBytes(root.service.connection.txBytes) }

          MetricLabel { text: "IP address" }
          MetricValue { text: root.service.connection.ip || "--" }
          MetricLabel { text: "Gateway" }
          MetricValue { text: root.service.connection.gateway || "--" }
        }
      }

      Rectangle {
        visible: root.service.hasConnection
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Section {
        title: root.service.wifiDevice ? "Wi-Fi" : "Wi-Fi · unavailable"

        ActionButton {
          visible: root.service.wifiDevice !== null
          width: 88
          label: root.service.scanning ? "Scanning…" : "Scan"
          available: !root.service.scanning
          onActivated: root.service.scan()
        }

        Text {
          width: parent.width
          visible: root.service.wifiDevice === null
          color: root.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: "No Wi-Fi adapter"
        }

        Repeater {
          model: root.service.wifiNetworks

          delegate: WifiRow {
            required property var modelData
            network: modelData
          }
        }

        Text {
          width: parent.width
          visible: root.service.wifiDevice !== null && !root.service.scanning && root.service.wifiNetworks.length === 0
          color: root.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: root.service.wifiEnabled ? "No networks found" : "Wi-Fi is off"
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
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 13
      text: parent.title
    }
  }

  component MetricLabel: Text {
    Layout.fillWidth: true
    color: root.shell.palette.off
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
  }

  component MetricValue: Text {
    Layout.fillWidth: true
    color: root.shell.palette.fg
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideLeft
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
    // `active` is the current state, `activeFocus` is where the keyboard is.
    // The border carries the second so both stay readable at once.
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    opacity: available ? 1 : 0.45

    // Visibility governs chain membership, `available` does not: every Wi-Fi
    // action sets `busy`, and dropping the focused button out of the chain
    // while its own action runs would strand the focus.
    activeFocusOnTab: button.visible
    Keys.onReturnPressed: if (button.available) button.activated()
    Keys.onEnterPressed: if (button.available) button.activated()
    Keys.onSpacePressed: if (button.available) button.activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
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
    required property var device

    width: parent.width
    height: 38
    radius: 4
    color: "transparent"
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
      text: root.service.deviceTypeName(parent.device)
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 13
      text: root.service.deviceDetail(parent.device)
    }

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 92
      anchors.right: parent.right
      anchors.rightMargin: 160
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 13
      text: parent.device.name
      elide: Text.ElideRight
    }
  }

  component WifiRow: Column {
    id: row

    required property var network

    width: parent.width
    spacing: 4

    Rectangle {
      width: parent.width
      height: 42
      radius: 4
      color: row.network.connected ? root.shell.palette.sel : "transparent"
      border.color: root.shell.palette.dim
      border.width: 1

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        text: Model.wifiIconFor(row.network.signal)
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 34
        anchors.right: action.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        text: row.network.ssid + " · " + root.service.wifiStatus(row.network)
        elide: Text.ElideRight
      }

      ActionButton {
        id: action
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.service.wifiAction(row.network) !== ""
        width: visible ? 74 : 0
        label: root.service.wifiAction(row.network)
        available: !root.service.busy
        onActivated: root.service.activate(row.network)
      }

      MouseArea {
        anchors.left: parent.left
        anchors.right: action.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: !root.service.busy
        onClicked: root.service.activate(row.network)
      }
    }

    Rectangle {
      width: parent.width
      height: visible ? 38 : 0
      visible: root.service.passwordSsid === row.network.ssid
      radius: 4
      color: root.shell.palette.sel

      TextField {
        id: passphrase
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.right: join.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        placeholderText: "Passphrase"
        placeholderTextColor: root.shell.palette.off
        echoMode: TextInput.Password
        selectByMouse: true
        background: Rectangle {
          radius: 3
          color: root.shell.palette.bg
          border.color: root.shell.palette.dim
          border.width: 1
        }
        onAccepted: root.service.connectWithPassphrase(row.network.ssid, text)
      }

      ActionButton {
        id: join
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 54
        label: "Join"
        available: passphrase.text.length > 0 && !root.service.busy
        onActivated: root.service.connectWithPassphrase(row.network.ssid, passphrase.text)
      }
    }

    Text {
      width: parent.width
      visible: root.service.failureSsid === row.network.ssid && root.service.failureReason !== ""
      color: root.shell.palette.off
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 12
      text: root.service.failureReason
    }

    ActionButton {
      visible: Model.canForgetNetwork(row.network)
      width: 74
      label: "Forget"
      available: !root.service.busy
      onActivated: root.service.forget(row.network.ssid)
    }
  }
}
