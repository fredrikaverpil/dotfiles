import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/network/NetworkModel.js" as Model

Ui.Panel {
  id: root

  required property var service

  cardHeight: 560
  keyNavigation: true

  Binding {
    target: root.service
    property: "active"
    value: root.shown
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

      Text {
        width: parent.width
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 18
        text: "Network"
      }

      Text {
        width: parent.width
        visible: !root.service.networkManagerAvailable
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: "NetworkManager is unavailable"
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Ui.Section {
        shell: root.shell
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
          font.family: Ui.Fonts.mono
          font.pixelSize: 13
          text: "No network devices"
        }

        ActionButton {
          visible: root.service.networkManagerAvailable
          width: 180
          label: "Connection settings…"
          onActivated: {
            root.close()
            Quickshell.execDetached(["nm-connection-editor"])
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Ui.Section {
        shell: root.shell
        visible: root.service.hasConnection
        title: "Connection · " + root.service.connection.iface

        GridLayout {
          width: parent.width
          columns: 4
          columnSpacing: 14
          rowSpacing: 5

          MetricLabel { text: "Ping (Cloudflare)" }
          MetricValue { text: Model.formatPing(root.service.ping.latency, root.service.hasPing) }
          MetricLabel { text: "Packet loss" }
          MetricValue { text: Model.formatPacketLoss(root.service.ping.packetLoss, root.service.hasPing) }

          MetricLabel { text: "Ping (gateway)" }
          MetricValue { text: Model.formatPing(root.service.gatewayPing.latency, root.service.hasGatewayPing) }
          MetricLabel { text: "Packet loss" }
          MetricValue { text: Model.formatPacketLoss(root.service.gatewayPing.packetLoss, root.service.hasGatewayPing) }

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

      Ui.Section {
        shell: root.shell
        title: root.service.wifiDevice ? "Wi-Fi" : "Wi-Fi · unavailable"

        Row {
          visible: root.service.wifiDevice !== null
          spacing: 8

          ActionButton {
            width: 88
            label: "Enabled"
            active: root.service.wifiEnabled
            onActivated: root.service.toggleWifi()
          }

          ActionButton {
            width: 88
            label: root.service.scanning ? "Scanning…" : "Scan"
            available: root.service.wifiEnabled && !root.service.scanning
            onActivated: root.service.scan()
          }
        }

        Text {
          width: parent.width
          visible: root.service.wifiDevice === null
          color: root.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 13
          text: "No Wi-Fi adapter"
        }

        Repeater {
          // ScriptModel diffs by identity, keeping delegates (and a passphrase being typed) alive.
          model: ScriptModel { values: root.service.wifiNetworks }

          delegate: WifiRow {
            required property var modelData
            network: modelData
          }
        }

        Repeater {
          model: ScriptModel {
            values: root.service.outOfRangeWifi
            objectProp: "uuid"
          }

          delegate: SavedRow {
            required property var modelData
            saved: modelData
          }
        }

        Text {
          width: parent.width
          visible: root.service.wifiDevice !== null && !root.service.scanning && root.service.wifiNetworks.length === 0
          color: root.shell.palette.off
          font.family: Ui.Fonts.mono
          font.pixelSize: 13
          text: !root.service.wifiEnabled
            ? "Wi-Fi is off"
            : root.service.wifiDevice && root.service.wifiDevice.scannerEnabled ? "No networks found" : "No known networks in range"
        }
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
    property bool available: true
    signal activated

    height: 28
    radius: 4
    color: active ? root.shell.palette.sel : "transparent"
    border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    opacity: available ? 1 : 0.45

    // Availability changes during Wi-Fi actions; visibility alone controls focus membership.
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
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: root.service.deviceTypeName(parent.device)
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
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
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: parent.device.name
      elide: Text.ElideRight
    }
  }

  component SavedRow: Rectangle {
    id: savedRow

    required property var saved

    width: parent.width
    height: 42
    radius: 4
    color: "transparent"
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 34
      anchors.right: forgetSaved.left
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: savedRow.saved.ssid + " · Out of range"
      elide: Text.ElideRight
    }

    ActionButton {
      id: forgetSaved
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      label: "Forget"
      available: !root.service.busy
      onActivated: root.service.forgetSaved(savedRow.saved.uuid)
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
        font.family: Ui.Fonts.mono
        font.pixelSize: 16
        text: Model.wifiIconFor(Model.wifiSignal(row.network))
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 34
        anchors.right: lock.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: row.network.name + " · " + root.service.wifiStatus(row.network)
        elide: Text.ElideRight
      }

      // Fixed offsets keep the columns aligned while the action buttons are hidden.
      Text {
        id: lock
        anchors.right: parent.right
        anchors.rightMargin: forget.visible ? 168 : 88
        anchors.verticalCenter: parent.verticalCenter
        visible: root.service.wifiSecured(row.network)
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: "󰌾"
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

      ActionButton {
        id: forget
        anchors.right: parent.right
        anchors.rightMargin: 86
        anchors.verticalCenter: parent.verticalCenter
        visible: Model.canForgetNetwork(row.network)
        width: visible ? 74 : 0
        label: "Forget"
        available: !root.service.busy
        onActivated: root.service.forget(row.network.name)
      }

      MouseArea {
        anchors.left: parent.left
        anchors.right: forget.visible ? forget.left : action.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: !root.service.busy
        onClicked: root.service.activate(row.network)
      }
    }

    Rectangle {
      width: parent.width
      height: visible ? 38 : 0
      visible: root.service.passwordSsid === row.network.name
      // Focus scrolls the field into view; it can open below the fold.
      onVisibleChanged: if (visible) passphrase.forceActiveFocus()
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
        font.family: Ui.Fonts.mono
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
        onAccepted: root.service.connectWithPassphrase(row.network.name, text)
      }

      ActionButton {
        id: join
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 54
        label: "Join"
        available: passphrase.text.length > 0 && !root.service.busy
        onActivated: root.service.connectWithPassphrase(row.network.name, passphrase.text)
      }
    }

    Text {
      width: parent.width
      visible: root.service.failureSsid === row.network.name && root.service.failureReason !== ""
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: root.service.failureReason
    }
  }
}
