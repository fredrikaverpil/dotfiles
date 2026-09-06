
import QtQuick
import Quickshell.Io
import Quickshell.Networking

import "NetworkModel.js" as Model

Item {
  id: root

  property bool active: false

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
  readonly property bool wifiEnabled: Networking.wifiEnabled

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

  function actionState() {
    return {
      actionNetwork: actionNetwork,
      actionSsid: actionSsid,
      actionKind: actionKind,
      passwordSsid: passwordSsid,
      failureSsid: failureSsid,
      failureReason: failureReason,
    }
  }

  function applyActionState(state) {
    actionNetwork = state.actionNetwork
    actionSsid = state.actionSsid
    actionKind = state.actionKind
    passwordSsid = state.passwordSsid
    failureSsid = state.failureSsid
    failureReason = state.failureReason
  }

  function findDevice(type) { return Model.findDevice(networkDevices, type) }

  function findConnectedWifiNetwork() {
    return Model.findConnectedWifiNetwork(wifiNetworkObjects)
  }

  function networkForSsid(ssid) { return Model.networkForSsid(wifiNetworkObjects, ssid) }

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
    var nextDevice = active ? wifiDevice : null
    if (scannerDevice && scannerDevice !== nextDevice) scannerDevice.scannerEnabled = false
    scannerDevice = nextDevice
    if (scannerDevice) scannerDevice.scannerEnabled = enabled
  }

  function scan() {
    if (!wifiDevice) return
    scanning = true
    setScannerEnabled(false)
    Qt.callLater(function() {
      if (root.active) root.setScannerEnabled(true)
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
    if (!active || !iface || internetPing.running) return
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

  function ipFor(device) { return Model.ipFor(device, ipAddresses) }

  function deviceTypeName(device) {
    return Model.deviceType(device.type, DeviceType)
  }

  function deviceDetail(device) {
    return Model.deviceDetail(device, ipAddresses, DeviceType, ConnectionState)
  }

  function wifiStatus(network) {
    return Model.wifiStatus(network, actionSsid, actionKind)
  }

  function wifiAction(network) {
    return Model.wifiAction(network, actionSsid, WifiSecurityType.Open, WifiSecurityType.Owe)
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
    var next = Model.beginAction(actionState(), kind, network)
    if (!next) return false
    applyActionState(next)
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
    applyActionState(Model.clearAction(actionState()))
    refresh()
  }

  function failAction(reason) {
    var next = Model.failedAction(
      actionState(), reason, ConnectionFailReason, WifiSecurityType.Open, WifiSecurityType.Owe)
    if (!next) return
    actionTimeout.stop()
    applyActionState(next)
    refresh()
  }

  function checkActionCompletion() {
    if (Model.isActionComplete(actionState())) clearAction()
  }

  function connectionFailureReason(reason) {
    return Model.connectionFailureReason(reason, ConnectionFailReason)
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
        type: deviceTypeName(device),
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

  onActiveChanged: {
    if (active) {
      refresh()
      if (wifiDevice) scan()
    } else {
      passwordSsid = ""
      setScannerEnabled(false)
    }
  }

  onWifiDeviceChanged: {
    setScannerEnabled(active)
    syncWifiNetworks()
  }
  onWifiNetworkObjectsChanged: syncWifiNetworks()

  Component.onCompleted: refresh()
  Component.onDestruction: {
    if (scannerDevice) scannerDevice.scannerEnabled = false
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
    running: root.active
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
}
