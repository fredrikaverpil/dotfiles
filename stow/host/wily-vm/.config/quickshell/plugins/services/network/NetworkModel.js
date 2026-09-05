// Network presentation helpers. Keep this data-only: Quickshell.Networking
// objects can disappear during a scan, so Panel.qml reduces them to plain rows
// before handing them to delegates. Run `node Model.js` for the self-check.

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

// OWE encrypts traffic without authenticating the user, so it needs no
// passphrase. Unknown security remains credentialed as the safe fallback.
function requiresCredentials(security, openSecurity, oweSecurity) {
  return security !== openSecurity && security !== oweSecurity
}

function canForgetNetwork(network) {
  return !!(network && network.known && !network.connected)
}

// NetworkDevice.address is its MAC address, not an IP address. `ip -j` fills
// that gap; retain the first global IPv4 address for each interface.
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

// Rates are deltas between consecutive counter samples. Reset when the active
// interface changes or a counter rolls over, so a reconnect never produces a
// giant made-up transfer spike.
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

function demo() {
  var assert = require("assert")
  var types = { Wifi: "wifi", Wired: "wired" }
  var states = {
    Connected: "connected",
    Connecting: "connecting",
    Disconnecting: "disconnecting",
    Disconnected: "disconnected",
  }

  assert.strictEqual(connectionIcon("ethernet", -1), "󰈀")
  assert.strictEqual(connectionIcon("disconnected", -1), "󰤮")
  assert.strictEqual(wifiIconFor(0), "󰤯")
  assert.strictEqual(wifiIconFor(100), "󰤨")
  assert.strictEqual(deviceType(types.Wifi, types), "Wi-Fi")
  assert.strictEqual(deviceType(types.Wired, types), "Ethernet")
  assert.strictEqual(connectionState(states.Connected, states), "Connected")
  assert.strictEqual(connectionState("other", states), "Unknown")

  var rows = sortWifiRows([
    { ssid: "weak", connected: false, known: false, signal: 10 },
    { ssid: "saved", connected: false, known: true, signal: 20 },
    { ssid: "current", connected: true, known: true, signal: 5 },
  ])
  assert.deepStrictEqual(rows.map(function(row) { return row.ssid }), ["current", "saved", "weak"])
  assert.strictEqual(requiresCredentials("open", "open", "owe"), false)
  assert.strictEqual(requiresCredentials("owe", "open", "owe"), false)
  assert.strictEqual(requiresCredentials("wpa2", "open", "owe"), true)
  assert.strictEqual(canForgetNetwork({ known: true, connected: false }), true)
  assert.strictEqual(canForgetNetwork({ known: true, connected: true }), false)

  var addresses = parseIpv4Addresses(JSON.stringify([
    {
      ifname: "lo",
      addr_info: [{ family: "inet", local: "127.0.0.1", scope: "host" }],
    },
    {
      ifname: "enp0s1",
      addr_info: [
        { family: "inet6", local: "fe80::1", scope: "link" },
        { family: "inet", local: "192.0.2.4", scope: "global" },
      ],
    },
  ]))
  assert.deepStrictEqual(addresses, { enp0s1: "192.0.2.4" })
  assert.deepStrictEqual(parseIpv4Addresses("invalid"), {})

  assert.deepStrictEqual(parseRoute('[{"dev":"wlan0","prefsrc":"192.0.2.4","gateway":"192.0.2.1"}]'), {
    iface: "wlan0", ip: "192.0.2.4", gateway: "192.0.2.1",
  })
  assert.deepStrictEqual(parseLinkStats('[{"ifname":"wlan0","stats64":{"rx":{"bytes":2048},"tx":{"bytes":1024}}}]'), {
    iface: "wlan0", rxBytes: 2048, txBytes: 1024,
  })

  var firstTransfer = transferState({}, { iface: "wlan0", rxBytes: 1000, txBytes: 2000 }, 10)
  var secondTransfer = transferState(firstTransfer, { iface: "wlan0", rxBytes: 3000, txBytes: 2500 }, 12)
  assert.strictEqual(secondTransfer.receivingRate, 1000)
  assert.strictEqual(secondTransfer.sendingRate, 250)
  assert.strictEqual(transferState(secondTransfer, { iface: "eth0", rxBytes: 3, txBytes: 4 }, 14).receivingRate, 0)

  assert.strictEqual(parsePing("64 bytes from 1.1.1.1: time=12.5 ms"), 12.5)
  assert.strictEqual(parsePing("100% packet loss"), null)
  var firstPing = pingState({}, "wlan0", 10, 24, 5)
  var secondPing = pingState(firstPing, "wlan0", null, 24, 5)
  assert.strictEqual(secondPing.latency, 10)
  assert.strictEqual(secondPing.packetLoss, 50)
  assert.strictEqual(formatBytes(1024), "1.0 KB")
  assert.strictEqual(formatRate(1024), "1.0 KB/s")
  assert.strictEqual(formatPing(-1, true), "Timeout")
  assert.strictEqual(formatPacketLoss(50, true), "50%")

  console.log("ok")
}

if (typeof module !== "undefined") {
  module.exports = {
    wifiIconFor: wifiIconFor,
    connectionIcon: connectionIcon,
    deviceType: deviceType,
    connectionState: connectionState,
    wifiRow: wifiRow,
    sortWifiRows: sortWifiRows,
    requiresCredentials: requiresCredentials,
    canForgetNetwork: canForgetNetwork,
    parseIpv4Addresses: parseIpv4Addresses,
    parseRoute: parseRoute,
    parseLinkStats: parseLinkStats,
    transferState: transferState,
    parsePing: parsePing,
    pingState: pingState,
    formatBytes: formatBytes,
    formatRate: formatRate,
    formatPing: formatPing,
    formatPacketLoss: formatPacketLoss,
  }
  if (require.main === module) demo()
}
