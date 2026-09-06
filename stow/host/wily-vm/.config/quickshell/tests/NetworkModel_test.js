import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Network = createRequire(import.meta.url)("../plugins/services/network/NetworkModel.js")

const types = { Wifi: "wifi", Wired: "wired" }
const states = { Connected: "connected", Connecting: "connecting", Disconnecting: "disconnecting", Disconnected: "disconnected" }
const reasons = {
  NoSecrets: "no-secrets", WifiAuthTimeout: "auth-timeout", WifiNetworkLost: "lost",
  WifiClientDisconnected: "disconnected", WifiClientFailed: "failed",
}

Deno.test("network display helpers cover devices, Wi-Fi rows, and status", () => {
  assertEquals(Network.wifiIconFor(0), "󰤯")
  assertEquals(Network.wifiIconFor(100), "󰤨")
  assertEquals(Network.connectionIcon("ethernet", 0), "󰈀")
  assertEquals(Network.deviceType(types.Wifi, types), "Wi-Fi")
  assertEquals(Network.connectionState(states.Connected, states), "Connected")
  assertEquals(Network.wifiRow({ name: "Home", signalStrength: 0.72, known: true }), {
    connected: false, known: true, ssid: "Home", signal: 72, security: undefined,
  })
  assertEquals(Network.wifiRow({}), null)
  assertEquals(Network.sortWifiRows([{ ssid: "b", connected: false, known: false, signal: 1 }, { ssid: "a", connected: true, known: false, signal: 1 }]).map(row => row.ssid), ["a", "b"])
  assertEquals(Network.wifiStatus({ ssid: "Home", connected: false, known: true }, "Home", "connect"), "Connecting…")
  assertEquals(Network.wifiAction({ ssid: "Home", security: "wpa", known: false }, "", "open", "owe"), "Join")
})

Deno.test("network parsers and rolling measurements handle bad output", () => {
  assertEquals(Network.parseIpv4Addresses("invalid"), {})
  assertEquals(Network.parseIpv4Addresses('[{"ifname":"eth0","addr_info":[{"family":"inet","local":"192.0.2.2","scope":"global"}]}]'), { eth0: "192.0.2.2" })
  assertEquals(Network.parseRoute("invalid"), { iface: "", ip: "", gateway: "" })
  assertEquals(Network.parseLinkStats("invalid"), { iface: "", rxBytes: null, txBytes: null })
  assertEquals(Network.parsePing("64 bytes: time=1.5 ms"), 1.5)
  assertEquals(Network.appendPingSample([1, 2], 3, 2), [2, 3])
  assertEquals(Network.averagePing([1, null, 3], 3), 2)
  assertEquals(Network.packetLoss([1, null, null]), 67)
  assertEquals(Network.formatBytes(-1), "--")
  assertEquals(Network.formatPing(1.25, true), "1.3 ms")
  assertEquals(Network.formatPacketLoss(50, false), "--")
})

Deno.test("network routes reset transfer state and retain valid rates", () => {
  const first = Network.transferState({}, { iface: "wlan0", rxBytes: 100, txBytes: 200 }, 10)
  assertEquals(first.receivingRate, 0)
  const next = Network.transferState(first, { iface: "wlan0", rxBytes: 300, txBytes: 260 }, 12)
  assertEquals(next.receivingRate, 100)
  assertEquals(next.sendingRate, 30)
  assertEquals(Network.transferState(next, { iface: "wlan0", rxBytes: 1, txBytes: 1 }, 13).receivingRate, 0)
  assertEquals(Network.pingState({}, "wlan0", 10, 2, 2), { iface: "wlan0", samples: [10], latency: 10, packetLoss: 0 })
})

Deno.test("network action state has explicit begin, completion, and failure transitions", () => {
  const network = { name: "Home", security: "wpa", connected: false, known: true, stateChanging: false }
  const state = { actionKind: "", passwordSsid: "", failureSsid: "", failureReason: "" }
  const started = Network.beginAction(state, "connect", network)
  assertEquals(started.actionSsid, "Home")
  assertEquals(Network.beginAction(started, "disconnect", network), null)
  assertEquals(Network.isActionComplete({ ...started, actionNetwork: { ...network, connected: true } }), true)
  assertEquals(Network.clearAction(started), {
    actionNetwork: null, actionSsid: "", actionKind: "", passwordSsid: "", failureSsid: "", failureReason: "",
  })
  assertEquals(Network.failedAction(started, reasons.NoSecrets, reasons, "open", "owe"), {
    actionNetwork: null, actionSsid: "", actionKind: "", passwordSsid: "Home", failureSsid: "Home", failureReason: "Passphrase required",
  })
  assertEquals(Network.connectionFailureReason(reasons.WifiAuthTimeout, reasons), "Wrong password")
})

Deno.test("network device lookup and details handle disconnected fallbacks", () => {
  const wifi = { name: "wlan0", type: types.Wifi, connected: false, state: states.Connecting }
  const wired = { name: "eth0", type: types.Wired, connected: true, state: states.Connected }
  assertEquals(Network.findDevice([wifi, wired], types.Wifi), wifi)
  assertEquals(Network.findDevice([wifi, wired], types.Wired), wired)
  assertEquals(Network.findConnectedWifiNetwork([wifi]), null)
  assertEquals(Network.networkForSsid([{ name: "Home" }], "Home"), { name: "Home" })
  assertEquals(Network.ipFor(wired, { eth0: "192.0.2.3" }), "192.0.2.3")
  assertEquals(Network.deviceDetail(wired, { eth0: "192.0.2.3" }, types, states), "Connected · 192.0.2.3")
})
