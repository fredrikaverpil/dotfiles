
function wifiIconFor(strength) {
  var icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
  var value = Number(strength)
  if (!isFinite(value)) value = 0
  var index = Math.max(0, Math.min(4, Math.ceil(value / 20) - 1))
  return icons[index]
}

function connectionIcon(kind, signalStrength) {
  if (kind === "wifi") return wifiIconFor(signalStrength)
  if (kind === "ethernet") return "󰈀"
  return "󰤮"
}

function deviceType(type, types) {
  if (type === types.Wifi) return "Wi-Fi"
  if (type === types.Wired) return "Ethernet"
  return "Network"
}

function connectionState(state, states) {
  if (state === states.Connected) return "Connected"
  if (state === states.Connecting) return "Connecting"
  if (state === states.Disconnecting) return "Disconnecting"
  if (state === states.Disconnected) return "Disconnected"
  return "Unknown"
}

function wifiRow(network) {
  if (!network || !network.name) return null

  return {
    connected: !!network.connected,
    known: !!network.known,
    ssid: String(network.name),
    signal: Math.round(Number(network.signalStrength || 0) * 100),
    security: network.security,
  }
}

function sortWifiRows(rows) {
  var networks = Array.isArray(rows) ? rows.slice() : []
  networks.sort(function(a, b) {
    if (a.connected !== b.connected) return a.connected ? -1 : 1
    if (a.known !== b.known) return a.known ? -1 : 1
    if (a.signal !== b.signal) return b.signal - a.signal
    return a.ssid.localeCompare(b.ssid)
  })
  return networks
}

function requiresCredentials(security, openSecurity, oweSecurity) {
  return security !== openSecurity && security !== oweSecurity
}

function canForgetNetwork(network) {
  return !!(network && network.known && !network.connected)
}

function parseIpv4Addresses(raw) {
  var interfaces
  try {
    interfaces = JSON.parse(String(raw || "[]"))
  } catch (error) {
    return {}
  }
  if (!Array.isArray(interfaces)) return {}

  var addresses = {}
  for (var i = 0; i < interfaces.length; i++) {
    var iface = interfaces[i]
    if (!iface || !iface.ifname || !Array.isArray(iface.addr_info)) continue

    for (var j = 0; j < iface.addr_info.length; j++) {
      var address = iface.addr_info[j]
      if (!address || address.family !== "inet" || !address.local) continue
      if (address.scope && address.scope !== "global") continue
      addresses[iface.ifname] = address.local
      break
    }
  }
  return addresses
}

function parseRoute(raw) {
  var routes
  try {
    routes = JSON.parse(String(raw || "[]"))
  } catch (error) {
    return { iface: "", ip: "", gateway: "" }
  }
  if (!Array.isArray(routes) || !routes[0]) return { iface: "", ip: "", gateway: "" }

  var route = routes[0]
  return {
    iface: String(route.dev || ""),
    ip: String(route.prefsrc || ""),
    gateway: String(route.gateway || ""),
  }
}

function parseLinkStats(raw) {
  var links
  try {
    links = JSON.parse(String(raw || "[]"))
  } catch (error) {
    return { iface: "", rxBytes: null, txBytes: null }
  }
  if (!Array.isArray(links) || !links[0]) return { iface: "", rxBytes: null, txBytes: null }

  var link = links[0]
  var stats = link.stats64 || link.stats || {}
  var rx = stats.rx || {}
  var tx = stats.tx || {}
  return {
    iface: String(link.ifname || ""),
    rxBytes: isFinite(Number(rx.bytes)) ? Number(rx.bytes) : null,
    txBytes: isFinite(Number(tx.bytes)) ? Number(tx.bytes) : null,
  }
}

function transferState(previous, sample, now) {
  var prev = previous || {}
  var next = sample || {}
  var iface = String(next.iface || "")
  var rx = Number(next.rxBytes)
  var tx = Number(next.txBytes)
  var time = Number(now)

  if (!iface || !isFinite(rx) || !isFinite(tx) || !isFinite(time)) {
    return {
      iface: iface,
      rxBytes: rx,
      txBytes: tx,
      sampleTime: time,
      receivingRate: 0,
      sendingRate: 0,
    }
  }

  var previousTime = Number(prev.sampleTime || 0)
  if (iface !== (prev.iface || "") || previousTime === 0
      || rx < Number(prev.rxBytes || 0) || tx < Number(prev.txBytes || 0)) {
    return {
      iface: iface,
      rxBytes: rx,
      txBytes: tx,
      sampleTime: time,
      receivingRate: 0,
      sendingRate: 0,
    }
  }

  var dt = time - previousTime
  var receivingRate = Number(prev.receivingRate || 0)
  var sendingRate = Number(prev.sendingRate || 0)
  if (dt > 0) {
    receivingRate = Math.max(0, (rx - Number(prev.rxBytes || 0)) / dt)
    sendingRate = Math.max(0, (tx - Number(prev.txBytes || 0)) / dt)
  }

  return {
    iface: iface,
    rxBytes: rx,
    txBytes: tx,
    sampleTime: time,
    receivingRate: receivingRate,
    sendingRate: sendingRate,
  }
}

function parsePing(raw) {
  var match = /time[=<]([0-9.]+)/.exec(String(raw || ""))
  if (!match) return null
  var value = Number(match[1])
  return isFinite(value) && value >= 0 ? value : null
}

function appendPingSample(samples, sample, limit) {
  var next = Array.isArray(samples) ? samples.slice() : []
  next.push(sample)
  while (next.length > limit) next.shift()
  return next
}

function averagePing(samples, limit) {
  var values = Array.isArray(samples) ? samples : []
  var start = Math.max(0, values.length - limit)
  var total = 0
  var count = 0
  for (var i = start; i < values.length; i++) {
    if (typeof values[i] !== "number" || !isFinite(values[i])) continue
    total += values[i]
    count++
  }
  return count > 0 ? total / count : -1
}

function packetLoss(samples) {
  var values = Array.isArray(samples) ? samples : []
  if (values.length === 0) return 0
  var lost = values.filter(function(value) { return value === null }).length
  return Math.round((lost / values.length) * 100)
}

function pingState(previous, iface, sample, limit, averageLimit) {
  var prev = previous || {}
  var currentIface = String(iface || "")
  var window = Math.max(1, Number(limit) || 24)
  var averageWindow = Math.max(1, Number(averageLimit) || 5)
  var samples = currentIface !== (prev.iface || "") ? [] : prev.samples
  samples = appendPingSample(samples, sample, window)

  return {
    iface: currentIface,
    samples: samples,
    latency: averagePing(samples, averageWindow),
    packetLoss: packetLoss(samples),
  }
}

function formatBytes(bytes) {
  var value = Number(bytes)
  if (!isFinite(value) || value < 0) return "--"
  if (value < 1024) return Math.round(value) + " B"
  if (value < 1024 * 1024) return (value / 1024).toFixed(1) + " KB"
  if (value < 1024 * 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MB"
  return (value / (1024 * 1024 * 1024)).toFixed(2) + " GB"
}

function formatRate(bytesPerSecond) {
  return formatBytes(bytesPerSecond) + "/s"
}

function formatPing(latency, hasSamples) {
  if (!hasSamples) return "--"
  var value = Number(latency)
  if (!isFinite(value) || value < 0) return "Timeout"
  return value.toFixed(value > 0 && value < 10 ? 1 : 0) + " ms"
}

function formatPacketLoss(loss, hasSamples) {
  if (!hasSamples) return "--"
  var value = Number(loss)
  if (!isFinite(value) || value < 0) return "--"
  return Math.round(value) + "%"
}

function findDevice(devices, type) {
  var source = devices || []
  var fallback = null
  for (var index = 0; index < source.length; index++) {
    var device = source[index]
    if (!device || device.type !== type) continue
    if (device.connected) return device
    if (!fallback) fallback = device
  }
  return fallback
}

function findConnectedWifiNetwork(networks) {
  var source = networks || []
  for (var index = 0; index < source.length; index++) {
    if (source[index] && source[index].connected) return source[index]
  }
  return null
}

function networkForSsid(networks, ssid) {
  var source = networks || []
  for (var index = 0; index < source.length; index++) {
    if (source[index] && source[index].name === ssid) return source[index]
  }
  return null
}

function ipFor(device, addresses) {
  if (!device || !device.name) return ""
  return (addresses || {})[device.name] || ""
}

function deviceDetail(device, addresses, types, states) {
  var state = connectionState(device.state, states)
  var ip = ipFor(device, addresses)
  return ip ? state + " · " + ip : state
}

function wifiStatus(network, actionSsid, actionKind) {
  if (!network) return ""
  if (actionSsid === network.ssid) {
    if (actionKind === "connect") return "Connecting…"
    if (actionKind === "disconnect") return "Disconnecting…"
    if (actionKind === "forget") return "Forgetting…"
  }
  return network.connected ? "Connected" : network.known ? "Saved" : "Available"
}

function wifiAction(network, actionSsid, openSecurity, oweSecurity) {
  if (!network || actionSsid === network.ssid) return ""
  if (network.connected) return "Disconnect"
  return requiresCredentials(network.security, openSecurity, oweSecurity) && !network.known
    ? "Join"
    : "Connect"
}

function connectionFailureReason(reason, reasons) {
  if (reason === reasons.NoSecrets) return "Passphrase required"
  if (reason === reasons.WifiAuthTimeout) return "Wrong password"
  if (reason === reasons.WifiNetworkLost) return "Network lost"
  if (reason === reasons.WifiClientDisconnected) return "Disconnected"
  if (reason === reasons.WifiClientFailed) return "Connection failed"
  return "Failed to connect"
}

function beginAction(state, kind, network) {
  var current = state || {}
  if (!network || current.actionKind) return null
  return {
    actionNetwork: network,
    actionSsid: network.name || "",
    actionKind: kind,
    passwordSsid: current.passwordSsid || "",
    failureSsid: "",
    failureReason: "",
  }
}

function clearAction(state) {
  var current = state || {}
  return {
    actionNetwork: null,
    actionSsid: "",
    actionKind: "",
    passwordSsid: current.actionKind === "connect" ? "" : (current.passwordSsid || ""),
    failureSsid: current.failureSsid || "",
    failureReason: current.failureReason || "",
  }
}

function failedAction(state, reason, reasons, openSecurity, oweSecurity) {
  var current = state || {}
  if (!current.actionKind) return null
  var retryPassword = current.actionKind === "connect" && current.actionNetwork
    && requiresCredentials(current.actionNetwork.security, openSecurity, oweSecurity)
  return {
    actionNetwork: null,
    actionSsid: "",
    actionKind: "",
    passwordSsid: retryPassword ? current.actionSsid : (current.passwordSsid || ""),
    failureSsid: current.actionSsid || "",
    failureReason: connectionFailureReason(reason, reasons),
  }
}

function isActionComplete(state) {
  var current = state || {}
  var network = current.actionNetwork
  if (!network || !current.actionKind) return false
  if (current.actionKind === "connect") return !!network.connected
  if (current.actionKind === "disconnect") return !network.connected && !network.stateChanging
  return current.actionKind === "forget" && !network.known && !network.stateChanging
}
