import QtQuick
import QtTest
import "../modules/services/network/NetworkModel.js" as Network

TestCase {
    name: "NetworkModel"

    readonly property var types: ({
            Wifi: "wifi",
            Wired: "wired"
        })
    readonly property var connectionStates: ({
            Connected: "connected",
            Connecting: "connecting",
            Disconnecting: "disconnecting",
            Disconnected: "disconnected"
        })
    readonly property var reasons: ({
            NoSecrets: "no-secrets",
            WifiAuthTimeout: "auth-timeout",
            WifiNetworkLost: "lost",
            WifiClientDisconnected: "disconnected",
            WifiClientFailed: "failed"
        })

    function test_network_display_helpers_cover_devices_wi_fi_rows_and_status() {
        compare(Network.wifiIconFor(0), "󰤯");
        compare(Network.wifiIconFor(100), "󰤨");
        compare(Network.connectionIcon("ethernet", 0), "󰈀");
        compare(Network.deviceType(types.Wifi, types), "Wi-Fi");
        compare(Network.connectionState(connectionStates.Connected, connectionStates), "Connected");
        compare(Network.wifiSignal({
            signalStrength: 0.72
        }), 72);
        compare(Network.wifiSignal(null), 0);
        compare(Network.sortWifiNetworks([
            {
                name: "b",
                signalStrength: 0.9
            },
            {
                name: "a",
                connected: true,
                signalStrength: 0.1
            }
        ]).map(network => network.name), ["a", "b"]);
        compare(Network.wifiStatus({
            name: "Home",
            connected: false,
            known: true
        }, "Home", "connect"), "Connecting…");
        compare(Network.wifiAction({
            name: "Home",
            security: "wpa",
            known: false
        }, "", "open", "owe"), "Join");
    }

    function test_saved_wifi_parses_nmcli_and_filters_networks_in_range() {
        const raw = "connection.uuid:a\n802-11-wireless.ssid:Attic\n\n" + "connection.uuid:b\n802-11-wireless.ssid:Cafe\\:5G\n\nconnection.uuid:c\n802-11-wireless.ssid:\n";
        const saved = Network.parseSavedWifi(raw);
        compare(saved, [
            {
                uuid: "a",
                ssid: "Attic"
            },
            {
                uuid: "b",
                ssid: "Cafe:5G"
            }
        ]);
        compare(Network.outOfRangeWifi(saved, [
            {
                name: "Attic"
            },
            null]), [
            {
                uuid: "b",
                ssid: "Cafe:5G"
            }
        ]);
        compare(Network.parseSavedWifi(""), []);
    }

    function test_wifi_order_holds_positions_and_appends_new_networks() {
        const weak = {
            name: "Weak",
            signalStrength: 0.2
        };
        const strong = {
            name: "Strong",
            signalStrength: 0.9
        };
        const extra = {
            name: "Extra",
            signalStrength: 0.5
        };
        compare(Network.orderWifiNetworks([], [weak, strong]).map(network => network.name), ["Strong", "Weak"]);
        compare(Network.orderWifiNetworks([weak, strong], [strong, weak, extra]).map(network => network.name), ["Weak", "Strong", "Extra"]);
        compare(Network.orderWifiNetworks([weak, strong], [strong]).map(network => network.name), ["Strong"]);
        compare(Network.orderWifiNetworks([], [
            {
                signalStrength: 0.5
            }
        ]), []);
        verify(Network.sameWifiNetworks([weak, strong], [weak, strong]));
        verify(!Network.sameWifiNetworks([weak, strong], [strong, weak]));
        verify(!Network.sameWifiNetworks([weak], []));
    }

    function test_network_parsers_and_rolling_measurements_handle_bad_output() {
        compare(Network.parseIpv4Addresses("invalid"), {});
        compare(Network.parseIpv4Addresses('[{"ifname":"eth0","addr_info":[{"family":"inet","local":"192.0.2.2","scope":"global"}]}]'), {
            eth0: "192.0.2.2"
        });
        compare(Network.parseRoute("invalid"), {
            iface: "",
            ip: "",
            gateway: ""
        });
        compare(Network.parseLinkStats("invalid"), {});
        compare(Network.parseLinkStats('[{"ifname":"eth0","stats64":{"rx":{"bytes":10},"tx":{"bytes":20}}},{"ifname":"wg0"}]'), {
            eth0: {
                rxBytes: 10,
                txBytes: 20
            }
        });
        compare(Network.parseDefaultRoutes("invalid"), {});
        compare(Network.parseDefaultRoutes('[{"dst":"default","gateway":"10.0.0.1","dev":"eth0","metric":100},' + '{"dst":"default","gateway":"10.0.0.9","dev":"eth0","metric":700},' + '{"dst":"default","gateway":"192.168.1.1","dev":"wlan0","metric":600},{"dst":"default","dev":"wg0"}]'), {
            eth0: "10.0.0.1",
            wlan0: "192.168.1.1",
            wg0: ""
        });
        compare(Network.parsePing("64 bytes: time=1.5 ms"), 1.5);
        compare(Network.appendPingSample([1, 2], 3, 2), [2, 3]);
        compare(Network.averagePing([1, null, 3], 3), 2);
        compare(Network.packetLoss([1, null, null]), 67);
        compare(Network.formatBytes(-1), "--");
        compare(Network.formatPing(1.25, true), "1.3 ms");
        compare(Network.formatPacketLoss(50, false), "--");
    }

    function test_network_routes_reset_transfer_state_and_retain_valid_rates() {
        const first = Network.transferState({}, {
            iface: "wlan0",
            rxBytes: 100,
            txBytes: 200
        }, 10);
        compare(first.receivingRate, 0);
        const next = Network.transferState(first, {
            iface: "wlan0",
            rxBytes: 300,
            txBytes: 260
        }, 12);
        compare(next.receivingRate, 100);
        compare(next.sendingRate, 30);
        compare(Network.transferState(next, {
            iface: "wlan0",
            rxBytes: 1,
            txBytes: 1
        }, 13).receivingRate, 0);
        compare(Network.pingState({}, "wlan0", 10, 2, 2), {
            iface: "wlan0",
            samples: [10],
            latency: 10,
            packetLoss: 0
        });
    }

    function test_device_details_track_each_iface_and_its_pings() {
        // Arrange
        const addresses = {
            eth0: "10.0.0.5",
            wlan0: "192.168.1.4"
        };
        const gateways = {
            eth0: "10.0.0.1",
            wlan0: "192.168.1.1"
        };
        const first = Network.deviceDetails({}, ["eth0", "wlan0"], addresses, gateways, {
            eth0: {
                rxBytes: 100,
                txBytes: 200
            }
        }, 10);

        // Act
        const pinged = Network.recordDevicePing(Network.recordDevicePing(first, "eth0", "ping", "eth0", "time=9 ms"), "eth0", "gatewayPing", "eth0 10.0.0.1", "time=2 ms");
        const stale = Network.recordDevicePing(pinged, "eth0", "gatewayPing", "eth0 10.0.0.254", "time=2 ms");
        const moved = Network.deviceDetails(pinged, ["eth0"], addresses, {
            eth0: "10.0.0.254"
        }, {
            eth0: {
                rxBytes: 300,
                txBytes: 260
            }
        }, 12);

        // Assert
        compare(first, {
            eth0: {
                ip: "10.0.0.5",
                gateway: "10.0.0.1",
                transfer: {
                    iface: "eth0",
                    rxBytes: 100,
                    txBytes: 200,
                    sampleTime: 10,
                    receivingRate: 0,
                    sendingRate: 0
                },
                ping: {
                    iface: "eth0",
                    samples: [],
                    latency: -1,
                    packetLoss: 0
                },
                gatewayPing: {
                    iface: "eth0 10.0.0.1",
                    samples: [],
                    latency: -1,
                    packetLoss: 0
                }
            },
            wlan0: {
                ip: "192.168.1.4",
                gateway: "192.168.1.1",
                transfer: null,
                ping: {
                    iface: "wlan0",
                    samples: [],
                    latency: -1,
                    packetLoss: 0
                },
                gatewayPing: {
                    iface: "wlan0 192.168.1.1",
                    samples: [],
                    latency: -1,
                    packetLoss: 0
                }
            }
        });
        verify(stale === pinged);
        compare(moved, {
            eth0: {
                ip: "10.0.0.5",
                gateway: "10.0.0.254",
                transfer: {
                    iface: "eth0",
                    rxBytes: 300,
                    txBytes: 260,
                    sampleTime: 12,
                    receivingRate: 100,
                    sendingRate: 30
                },
                ping: {
                    iface: "eth0",
                    samples: [9],
                    latency: 9,
                    packetLoss: 0
                },
                gatewayPing: {
                    iface: "eth0 10.0.0.254",
                    samples: [],
                    latency: -1,
                    packetLoss: 0
                }
            }
        });
    }

    function test_detail_metrics_format_a_device_for_the_panel_data() {
        return [
            {
                tag: "unmeasured",
                detail: null,
                want: {
                    ip: "--",
                    gateway: "--",
                    ping: "--",
                    loss: "--",
                    gatewayPing: "--",
                    gatewayLoss: "--",
                    receiving: "--",
                    sending: "--",
                    downloaded: "--",
                    uploaded: "--"
                }
            },
            {
                tag: "measured",
                detail: {
                    ip: "10.0.0.5",
                    gateway: "10.0.0.1",
                    transfer: {
                        rxBytes: 2048,
                        txBytes: 512,
                        receivingRate: 1024,
                        sendingRate: 0
                    },
                    ping: {
                        samples: [12],
                        latency: 12,
                        packetLoss: 0
                    },
                    gatewayPing: {
                        samples: [null],
                        latency: -1,
                        packetLoss: 100
                    }
                },
                want: {
                    ip: "10.0.0.5",
                    gateway: "10.0.0.1",
                    ping: "12 ms",
                    loss: "0%",
                    gatewayPing: "Timeout",
                    gatewayLoss: "100%",
                    receiving: "1.0 KB/s",
                    sending: "0 B/s",
                    downloaded: "2.0 KB",
                    uploaded: "512 B"
                }
            }
        ];
    }

    function test_detail_metrics_format_a_device_for_the_panel(data) {
        compare(Network.detailMetrics(data.detail), data.want);
    }

    function test_network_action_state_has_explicit_begin_completion_and_failure_transitions() {
        const network = {
            name: "Home",
            security: "wpa",
            connected: false,
            known: true,
            stateChanging: false
        };
        const state = {
            actionKind: "",
            passwordSsid: "",
            failureSsid: "",
            failureReason: ""
        };
        const started = Network.beginAction(state, "connect", network);
        compare(started.actionSsid, "Home");
        compare(Network.beginAction(started, "disconnect", network), null);
        compare(Network.isActionComplete(Object.assign({}, started, {
            actionNetwork: Object.assign({}, network, {
                connected: true
            })
        })), true);
        compare(Network.clearAction(started), {
            actionNetwork: null,
            actionSsid: "",
            actionKind: "",
            passwordSsid: "",
            failureSsid: "",
            failureReason: ""
        });
        compare(Network.failedAction(started, reasons.NoSecrets, reasons, "open", "owe"), {
            actionNetwork: null,
            actionSsid: "",
            actionKind: "",
            passwordSsid: "Home",
            failureSsid: "Home",
            failureReason: "Passphrase required"
        });
        compare(Network.connectionFailureReason(reasons.WifiAuthTimeout, reasons), "Wrong password");
    }

    function test_network_device_lookup_and_details_handle_disconnected_fallbacks() {
        const wifi = {
            name: "wlan0",
            type: types.Wifi,
            connected: false,
            state: connectionStates.Connecting
        };
        const wired = {
            name: "eth0",
            type: types.Wired,
            connected: true,
            state: connectionStates.Connected
        };
        compare(Network.findDevice([wifi, wired], types.Wifi), wifi);
        compare(Network.findDevice([wifi, wired], types.Wired), wired);
        compare(Network.findConnectedWifiNetwork([wifi]), null);
        compare(Network.networkForSsid([
            {
                name: "Home"
            }
        ], "Home"), {
            name: "Home"
        });
        compare(Network.ipFor(wired, {
            eth0: "192.0.2.3"
        }), "192.0.2.3");
        compare(Network.deviceDetail(wired, {
            eth0: "192.0.2.3"
        }, types, connectionStates), "Connected · 192.0.2.3");
    }
}
