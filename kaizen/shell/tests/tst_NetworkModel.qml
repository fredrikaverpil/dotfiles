import QtQuick
import QtTest
import "../plugins/services/network/NetworkModel.js" as Network

TestCase {
  name: "NetworkModel"

  readonly property var types: ({ Wifi: "wifi", Wired: "wired" })
  readonly property var connectionStates: ({ Connected: "connected", Connecting: "connecting", Disconnecting: "disconnecting", Disconnected: "disconnected" })
  readonly property var reasons: ({
    NoSecrets: "no-secrets", WifiAuthTimeout: "auth-timeout", WifiNetworkLost: "lost",
    WifiClientDisconnected: "disconnected", WifiClientFailed: "failed",
  })

  function test_network_display_helpers_cover_devices_wi_fi_rows_and_status() {
    compare(Network.wifiIconFor(0), "󰤯")
    compare(Network.wifiIconFor(100), "󰤨")
    compare(Network.connectionIcon("ethernet", 0), "󰈀")
    compare(Network.deviceType(types.Wifi, types), "Wi-Fi")
    compare(Network.connectionState(connectionStates.Connected, connectionStates), "Connected")
    compare(Network.wifiSignal({ signalStrength: 0.72 }), 72)
    compare(Network.wifiSignal(null), 0)
    compare(Network.sortWifiNetworks([{ name: "b", signalStrength: 0.9 }, { name: "a", connected: true, signalStrength: 0.1 }]).map(network => network.name), ["a", "b"])
    compare(Network.wifiStatus({ name: "Home", connected: false, known: true }, "Home", "connect"), "Connecting…")
    compare(Network.wifiAction({ name: "Home", security: "wpa", known: false }, "", "open", "owe"), "Join")
  }

  function test_saved_wifi_parses_nmcli_and_filters_networks_in_range() {
    const raw = "connection.uuid:a\n802-11-wireless.ssid:Attic\n\n"
      + "connection.uuid:b\n802-11-wireless.ssid:Cafe\\:5G\n\nconnection.uuid:c\n802-11-wireless.ssid:\n"
    const saved = Network.parseSavedWifi(raw)
    compare(saved, [{ uuid: "a", ssid: "Attic" }, { uuid: "b", ssid: "Cafe:5G" }])
    compare(Network.outOfRangeWifi(saved, [{ name: "Attic" }, null]), [{ uuid: "b", ssid: "Cafe:5G" }])
    compare(Network.parseSavedWifi(""), [])
  }

  function test_wifi_order_holds_positions_and_appends_new_networks() {
    const weak = { name: "Weak", signalStrength: 0.2 }
    const strong = { name: "Strong", signalStrength: 0.9 }
    const extra = { name: "Extra", signalStrength: 0.5 }
    compare(Network.orderWifiNetworks([], [weak, strong]).map(network => network.name), ["Strong", "Weak"])
    compare(Network.orderWifiNetworks([weak, strong], [strong, weak, extra]).map(network => network.name), ["Weak", "Strong", "Extra"])
    compare(Network.orderWifiNetworks([weak, strong], [strong]).map(network => network.name), ["Strong"])
    compare(Network.orderWifiNetworks([], [{ signalStrength: 0.5 }]), [])
    verify(Network.sameWifiNetworks([weak, strong], [weak, strong]))
    verify(!Network.sameWifiNetworks([weak, strong], [strong, weak]))
    verify(!Network.sameWifiNetworks([weak], []))
  }

  function test_network_parsers_and_rolling_measurements_handle_bad_output() {
    compare(Network.parseIpv4Addresses("invalid"), {})
    compare(Network.parseIpv4Addresses('[{"ifname":"eth0","addr_info":[{"family":"inet","local":"192.0.2.2","scope":"global"}]}]'), { eth0: "192.0.2.2" })
    compare(Network.parseRoute("invalid"), { iface: "", ip: "", gateway: "" })
    compare(Network.parseLinkStats("invalid"), { iface: "", rxBytes: null, txBytes: null })
    compare(Network.parsePing("64 bytes: time=1.5 ms"), 1.5)
    compare(Network.appendPingSample([1, 2], 3, 2), [2, 3])
    compare(Network.averagePing([1, null, 3], 3), 2)
    compare(Network.packetLoss([1, null, null]), 67)
    compare(Network.formatBytes(-1), "--")
    compare(Network.formatPing(1.25, true), "1.3 ms")
    compare(Network.formatPacketLoss(50, false), "--")
  }

  function test_network_routes_reset_transfer_state_and_retain_valid_rates() {
    const first = Network.transferState({}, { iface: "wlan0", rxBytes: 100, txBytes: 200 }, 10)
    compare(first.receivingRate, 0)
    const next = Network.transferState(first, { iface: "wlan0", rxBytes: 300, txBytes: 260 }, 12)
    compare(next.receivingRate, 100)
    compare(next.sendingRate, 30)
    compare(Network.transferState(next, { iface: "wlan0", rxBytes: 1, txBytes: 1 }, 13).receivingRate, 0)
    compare(Network.pingState({}, "wlan0", 10, 2, 2), { iface: "wlan0", samples: [10], latency: 10, packetLoss: 0 })
  }

  function test_network_action_state_has_explicit_begin_completion_and_failure_transitions() {
    const network = { name: "Home", security: "wpa", connected: false, known: true, stateChanging: false }
    const state = { actionKind: "", passwordSsid: "", failureSsid: "", failureReason: "" }
    const started = Network.beginAction(state, "connect", network)
    compare(started.actionSsid, "Home")
    compare(Network.beginAction(started, "disconnect", network), null)
    compare(Network.isActionComplete(Object.assign({}, started, {
      actionNetwork: Object.assign({}, network, { connected: true })
    })), true)
    compare(Network.clearAction(started), {
      actionNetwork: null, actionSsid: "", actionKind: "", passwordSsid: "", failureSsid: "", failureReason: "",
    })
    compare(Network.failedAction(started, reasons.NoSecrets, reasons, "open", "owe"), {
      actionNetwork: null, actionSsid: "", actionKind: "", passwordSsid: "Home", failureSsid: "Home", failureReason: "Passphrase required",
    })
    compare(Network.connectionFailureReason(reasons.WifiAuthTimeout, reasons), "Wrong password")
  }

  function test_network_device_lookup_and_details_handle_disconnected_fallbacks() {
    const wifi = { name: "wlan0", type: types.Wifi, connected: false, state: connectionStates.Connecting }
    const wired = { name: "eth0", type: types.Wired, connected: true, state: connectionStates.Connected }
    compare(Network.findDevice([wifi, wired], types.Wifi), wifi)
    compare(Network.findDevice([wifi, wired], types.Wired), wired)
    compare(Network.findConnectedWifiNetwork([wifi]), null)
    compare(Network.networkForSsid([{ name: "Home" }], "Home"), { name: "Home" })
    compare(Network.ipFor(wired, { eth0: "192.0.2.3" }), "192.0.2.3")
    compare(Network.deviceDetail(wired, { eth0: "192.0.2.3" }, types, connectionStates), "Connected · 192.0.2.3")
  }
}
