import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking

import "../../../Ui" as Ui
import "Model.js" as Model

// NetworkManager-backed network controls. Keep the panel deliberately smaller
// than Omarchy's counterpart: Quickshell handles devices, scans and Wi-Fi
// actions directly. The connection metrics use the same standard kernel and
// iproute data Omarchy's helper collects; the remaining extras wait for real
// hardware before deciding which of their scripts are worth porting.
Ui.Panel {
  id: root

  cardHeight: 560
  pinnable: true
  keyNavigation: true

  readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: findDevice(DeviceType.Wifi)
  readonly property var wiredDevice: findDevice(DeviceType.Wired)
  readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks
    ? wifiDevice.networks.values
    : []
  readonly property var connectedWifiNetwork: findConnectedWifiNetwork()
  readonly property string kind: wiredDevice && wiredDevice.connected
    ? "ethernet"
    : connectedWifiNetwork
      ? "wifi"
      : "disconnected"
  readonly property int signalStrength: connectedWifiNetwork
    ? Math.round(Number(connectedWifiNetwork.signalStrength || 0) * 100)
    : -1
  readonly property string icon: Model.connectionIcon(kind, signalStrength)

  property var wifiNetworks: []
  property var ipAddresses: ({})
  property var scannerDevice: null
  property var actionNetwork: null
  property string actionSsid: ""
  property string actionKind: ""
  property string passwordSsid: ""
  property string failureSsid: ""
  property string failureReason: ""
  property bool scanning: false
  property var connection: ({ iface: "", ip: "", gateway: "", rxBytes: null, txBytes: null })
  property var transfer: ({
    iface: "", rxBytes: 0, txBytes: 0, sampleTime: 0, receivingRate: 0, sendingRate: 0,
  })
  property var ping: ({ iface: "", samples: [], latency: -1, packetLoss: 0 })

  readonly property bool busy: actionKind !== ""
  readonly property bool hasConnection: connection.iface !== ""
  readonly property bool hasTransfer: connection.rxBytes !== null && connection.txBytes !== null
  readonly property bool hasPing: ping.samples && ping.samples.length > 0

  function findDevice(type) {
    var fallback = null
    var devices = networkDevices || []
    for (var i = 0; i < devices.length; i++) {
      var device = devices[i]
      if (!device || device.type !== type) continue
      if (device.connected) return device
      if (!fallback) fallback = device
    }
    return fallback
  }

  function findConnectedWifiNetwork() {
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].connected) return networks[i]
    }
    return null
  }

  function networkForSsid(ssid) {
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].name === ssid) return networks[i]
    }
    return null
  }

  function syncWifiNetworks() {
    var rows = []
    var networks = wifiNetworkObjects || []
    for (var i = 0; i < networks.length; i++) {
      var row = Model.wifiRow(networks[i])
      if (row) rows.push(row)
    }
    wifiNetworks = Model.sortWifiRows(rows)
    checkActionCompletion()
  }

  function setScannerEnabled(enabled) {
    var nextDevice = shown ? wifiDevice : null
    if (scannerDevice && scannerDevice !== nextDevice) scannerDevice.scannerEnabled = false
    scannerDevice = nextDevice
    if (scannerDevice) scannerDevice.scannerEnabled = enabled
  }

  function scan() {
    if (!wifiDevice) return
    scanning = true
    setScannerEnabled(false)
    Qt.callLater(function() {
      if (root.shown) root.setScannerEnabled(true)
      scanFinished.restart()
    })
  }

  function refresh() {
    syncWifiNetworks()
    if (!ipAddressProcess.running) ipAddressProcess.running = true
    if (!routeProcess.running) routeProcess.running = true
  }

  function updateRoute(raw) {
    var route = Model.parseRoute(raw)
    var changed = route.iface !== connection.iface
    if (changed) {
      transfer = ({ iface: "", rxBytes: 0, txBytes: 0, sampleTime: 0, receivingRate: 0, sendingRate: 0 })
      ping = ({ iface: "", samples: [], latency: -1, packetLoss: 0 })
    }

    connection = {
      iface: route.iface,
      ip: route.ip,
      gateway: route.gateway,
      rxBytes: changed ? null : connection.rxBytes,
      txBytes: changed ? null : connection.txBytes,
    }
    if (!route.iface) return

    if (!linkStatsProcess.running) {
      linkStatsProcess.command = ["ip", "-j", "-s", "link", "show", "dev", route.iface]
      linkStatsProcess.running = true
    }
    startInternetPing(route.iface)
  }

  function updateLinkStats(raw) {
    var stats = Model.parseLinkStats(raw)
    if (!stats.iface || stats.iface !== connection.iface) return

    transfer = Model.transferState(transfer, stats, Date.now() / 1000)
    connection = {
      iface: connection.iface,
      ip: connection.ip,
      gateway: connection.gateway,
      rxBytes: stats.rxBytes,
      txBytes: stats.txBytes,
    }
  }

  function startInternetPing(iface) {
    if (!shown || !iface || internetPing.running) return
    internetPing.iface = iface
    internetPing.command = ["ping", "-n", "-I", iface, "-c", "1", "-W", "1", "1.1.1.1"]
    internetPing.running = true
  }

  function recordInternetPing(iface, raw) {
    if (iface !== connection.iface) return
    ping = Model.pingState(ping, iface, Model.parsePing(raw), 24, 5)
  }

  function setIpAddresses(raw) {
    ipAddresses = Model.parseIpv4Addresses(raw)
  }

  function ipFor(device) {
    if (!device || !device.name) return ""
    return ipAddresses[device.name] || ""
  }

  function deviceDetail(device) {
    var state = Model.connectionState(device.state, ConnectionState)
    var ip = ipFor(device)
    return ip ? state + " · " + ip : state
  }

  function wifiStatus(network) {
    if (!network) return ""
    if (actionSsid === network.ssid) {
      if (actionKind === "connect") return "Connecting…"
      if (actionKind === "disconnect") return "Disconnecting…"
      if (actionKind === "forget") return "Forgetting…"
    }
    return network.connected ? "Connected" : network.known ? "Saved" : "Available"
  }

  function wifiAction(network) {
    if (!network) return ""
    if (actionSsid === network.ssid) return ""
    if (network.connected) return "Disconnect"
    if (Model.requiresCredentials(network.security, WifiSecurityType.Open, WifiSecurityType.Owe)
        && !network.known) return "Join"
    return "Connect"
  }

  function activate(network) {
    if (!network || busy) return
    if (network.connected) {
      disconnect(network.ssid)
      return
    }
    if (Model.requiresCredentials(network.security, WifiSecurityType.Open, WifiSecurityType.Owe)
        && !network.known) {
      passwordSsid = network.ssid
      failureSsid = ""
      failureReason = ""
      return
    }
    connect(network.ssid)
  }

  function beginAction(kind, network) {
    if (!network || busy) return false
    actionNetwork = network
    actionSsid = network.name || ""
    actionKind = kind
    failureSsid = ""
    failureReason = ""
    actionTimeout.restart()
    return true
  }

  function connect(ssid) {
    var network = networkForSsid(ssid)
    if (beginAction("connect", network)) network.connect()
  }

  function connectWithPassphrase(ssid, passphrase) {
    if (!passphrase) return
    var network = networkForSsid(ssid)
    if (beginAction("connect", network)) network.connectWithPsk(passphrase)
  }

  function disconnect(ssid) {
    var network = networkForSsid(ssid)
    if (beginAction("disconnect", network)) network.disconnect()
  }

  function forget(ssid) {
    var network = networkForSsid(ssid)
    if (beginAction("forget", network)) network.forget()
  }

  function clearAction() {
    actionTimeout.stop()
    if (actionKind === "connect") passwordSsid = ""
    actionNetwork = null
    actionSsid = ""
    actionKind = ""
    refresh()
  }

  function failAction(reason) {
    if (!actionKind) return
    actionTimeout.stop()
    failureSsid = actionSsid
    failureReason = connectionFailureReason(reason)
    var retryPassword = actionKind === "connect"
      && actionNetwork
      && Model.requiresCredentials(actionNetwork.security, WifiSecurityType.Open, WifiSecurityType.Owe)
    if (retryPassword) passwordSsid = actionSsid
    actionNetwork = null
    actionSsid = ""
    actionKind = ""
    refresh()
  }

  function checkActionCompletion() {
    var network = actionNetwork
    if (!network || !actionKind) return
    if (actionKind === "connect" && network.connected) clearAction()
    else if (actionKind === "disconnect" && !network.connected && !network.stateChanging) clearAction()
    else if (actionKind === "forget" && !network.known && !network.stateChanging) clearAction()
  }

  function connectionFailureReason(reason) {
    if (reason === ConnectionFailReason.NoSecrets) return "Passphrase required"
    if (reason === ConnectionFailReason.WifiAuthTimeout) return "Wrong password"
    if (reason === ConnectionFailReason.WifiNetworkLost) return "Network lost"
    if (reason === ConnectionFailReason.WifiClientDisconnected) return "Disconnected"
    if (reason === ConnectionFailReason.WifiClientFailed) return "Connection failed"
    return "Failed to connect"
  }

  function toggleWifi() {
    if (!networkManagerAvailable || !wifiDevice) return
    Networking.wifiEnabled = !Networking.wifiEnabled
    if (Networking.wifiEnabled) scan()
  }

  function status() {
    var devices = []
    var source = networkDevices || []
    for (var i = 0; i < source.length; i++) {
      var device = source[i]
      if (!device) continue
      devices.push({
        name: device.name,
        type: Model.deviceType(device.type, DeviceType),
        state: Model.connectionState(device.state, ConnectionState),
        ip: ipFor(device),
      })
    }
    return JSON.stringify({
      kind: kind,
      wifiEnabled: Networking.wifiEnabled,
      devices: devices,
      connection: {
        iface: connection.iface,
        ip: connection.ip,
        gateway: connection.gateway,
        receivingRate: transfer.receivingRate,
        sendingRate: transfer.sendingRate,
        rxBytes: connection.rxBytes,
        txBytes: connection.txBytes,
        ping: ping.latency,
        packetLoss: ping.packetLoss,
      },
    })
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

  onShownChanged: {
    if (shown) {
      refresh()
      if (wifiDevice) scan()
    } else {
      passwordSsid = ""
      setScannerEnabled(false)
    }
  }

  onWifiDeviceChanged: {
    setScannerEnabled(shown)
    syncWifiNetworks()
  }
  onWifiNetworkObjectsChanged: syncWifiNetworks()

  Component.onCompleted: refresh()
  Component.onDestruction: {
    if (scannerDevice) scannerDevice.scannerEnabled = false
  }

  IpcHandler {
    target: "network"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.status() }
  }

  Connections {
    target: root.actionNetwork

    function onConnectedChanged() { root.checkActionCompletion() }
    function onKnownChanged() { root.checkActionCompletion() }
    function onStateChangingChanged() { root.checkActionCompletion() }
    function onConnectionFailed(reason) { root.failAction(reason) }
  }

  Process {
    id: ipAddressProcess
    command: ["ip", "-j", "-4", "address"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.setIpAddresses(text)
    }
  }

  Process {
    id: routeProcess
    command: ["ip", "-j", "route", "get", "1.1.1.1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateRoute(text)
    }
  }

  Process {
    id: linkStatsProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateLinkStats(text)
    }
  }

  Process {
    id: internetPing
    property string iface: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.recordInternetPing(internetPing.iface, text)
    }
  }

  Timer {
    id: ipPoll
    interval: 1500
    repeat: true
    running: root.shown
    onTriggered: root.refresh()
  }

  Timer {
    id: scanFinished
    interval: 1500
    repeat: false
    onTriggered: {
      root.scanning = false
      root.syncWifiNetworks()
    }
  }

  Timer {
    id: actionTimeout
    interval: 30000
    repeat: false
    onTriggered: root.failAction(ConnectionFailReason.Unknown)
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
          visible: root.wifiDevice !== null
          width: 92
          label: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
          active: Networking.wifiEnabled
          onActivated: root.toggleWifi()
        }
      }

      Text {
        width: parent.width
        visible: !root.networkManagerAvailable
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
          model: root.networkDevices

          delegate: DeviceRow {
            required property var modelData
            device: modelData
          }
        }

        Text {
          width: parent.width
          visible: root.networkDevices.length === 0
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
        visible: root.hasConnection
        title: "Connection · " + root.connection.iface

        GridLayout {
          width: parent.width
          columns: 4
          columnSpacing: 14
          rowSpacing: 5

          MetricLabel { text: "Ping" }
          MetricValue { text: Model.formatPing(root.ping.latency, root.hasPing) }
          MetricLabel { text: "Packet loss" }
          MetricValue { text: Model.formatPacketLoss(root.ping.packetLoss, root.hasPing) }

          MetricLabel { text: "Receiving" }
          MetricValue { text: root.hasTransfer ? Model.formatRate(root.transfer.receivingRate) : "--" }
          MetricLabel { text: "Sending" }
          MetricValue { text: root.hasTransfer ? Model.formatRate(root.transfer.sendingRate) : "--" }

          MetricLabel { text: "Downloaded" }
          MetricValue { text: Model.formatBytes(root.connection.rxBytes) }
          MetricLabel { text: "Uploaded" }
          MetricValue { text: Model.formatBytes(root.connection.txBytes) }

          MetricLabel { text: "IP address" }
          MetricValue { text: root.connection.ip || "--" }
          MetricLabel { text: "Gateway" }
          MetricValue { text: root.connection.gateway || "--" }
        }
      }

      Rectangle {
        visible: root.hasConnection
        width: parent.width
        height: 1
        color: root.shell.palette.dim
      }

      Section {
        title: root.wifiDevice ? "Wi-Fi" : "Wi-Fi · unavailable"

        ActionButton {
          visible: root.wifiDevice !== null
          width: 88
          label: root.scanning ? "Scanning…" : "Scan"
          available: !root.scanning
          onActivated: root.scan()
        }

        Text {
          width: parent.width
          visible: root.wifiDevice === null
          color: root.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: "No Wi-Fi adapter"
        }

        Repeater {
          model: root.wifiNetworks

          delegate: WifiRow {
            required property var modelData
            network: modelData
          }
        }

        Text {
          width: parent.width
          visible: root.wifiDevice !== null && !root.scanning && root.wifiNetworks.length === 0
          color: root.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: Networking.wifiEnabled ? "No networks found" : "Wi-Fi is off"
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
      text: Model.deviceType(parent.device.type, DeviceType)
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 13
      text: root.deviceDetail(parent.device)
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
        text: row.network.ssid + " · " + root.wifiStatus(row.network)
        elide: Text.ElideRight
      }

      ActionButton {
        id: action
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.wifiAction(row.network) !== ""
        width: visible ? 74 : 0
        label: root.wifiAction(row.network)
        available: !root.busy
        onActivated: root.activate(row.network)
      }

      MouseArea {
        anchors.left: parent.left
        anchors.right: action.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        enabled: !root.busy
        onClicked: root.activate(row.network)
      }
    }

    Rectangle {
      width: parent.width
      height: visible ? 38 : 0
      visible: root.passwordSsid === row.network.ssid
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
        onAccepted: root.connectWithPassphrase(row.network.ssid, text)
      }

      ActionButton {
        id: join
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 54
        label: "Join"
        available: passphrase.text.length > 0 && !root.busy
        onActivated: root.connectWithPassphrase(row.network.ssid, passphrase.text)
      }
    }

    Text {
      width: parent.width
      visible: root.failureSsid === row.network.ssid && root.failureReason !== ""
      color: root.shell.palette.off
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 12
      text: root.failureReason
    }

    ActionButton {
      visible: Model.canForgetNetwork(row.network)
      width: 74
      label: "Forget"
      available: !root.busy
      onActivated: root.forget(row.network.ssid)
    }
  }
}
