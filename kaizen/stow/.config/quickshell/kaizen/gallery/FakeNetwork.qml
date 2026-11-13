import QtQuick

import "../modules/services/network/NetworkModel.js" as Model

// The network service's members the view and bar button read, without NetworkManager.
QtObject {
    id: fake

    // Stand-ins for Quickshell's WifiSecurityType.
    readonly property var securities: ({
            Open: "open",
            Owe: "owe",
            Wpa: "wpa"
        })
    readonly property list<QtObject> all: [
        Network {
            name: "Hemma"
            signalStrength: 0.82
            security: fake.securities.Wpa
        },
        Network {
            name: "Hemma 5G"
            signalStrength: 0.64
            security: fake.securities.Wpa
        },
        Network {
            name: "Kafé Gratis"
            signalStrength: 0.48
            security: fake.securities.Open
        },
        Network {
            name: "Telia-7F3A21"
            signalStrength: 0.36
            security: fake.securities.Wpa
        },
        Network {
            name: "Grannens nätverk med ett mycket långt namn"
            signalStrength: 0.12
            security: fake.securities.Wpa
        },
        Network {
            name: "Bredband2-4C1E"
            signalStrength: 0.58
            security: fake.securities.Wpa
        },
        Network {
            name: "Comhem_9A2F"
            signalStrength: 0.44
            security: fake.securities.Wpa
        },
        Network {
            name: "TP-Link_7781"
            signalStrength: 0.4
            security: fake.securities.Wpa
        },
        Network {
            name: "Tele2 Hemnät"
            signalStrength: 0.31
            security: fake.securities.Wpa
        },
        Network {
            name: "ASUS_RT-AX58U"
            signalStrength: 0.27
            security: fake.securities.Wpa
        },
        Network {
            name: "DIRECT-HP-LaserJet"
            signalStrength: 0.22
            security: fake.securities.Open
        },
        Network {
            name: "Lägenhet 4B"
            signalStrength: 0.18
            security: fake.securities.Wpa
        },
        Network {
            name: "Ohana"
            signalStrength: 0.15
            security: fake.securities.Wpa
        },
        Network {
            name: "Gäst"
            signalStrength: 0.09
            security: fake.securities.Open
        },
        Network {
            name: "Netgear42"
            signalStrength: 0.05
            security: fake.securities.Wpa
        }
    ]
    readonly property var scenarios: ({
            "Wi-Fi": {
                manager: true,
                adapter: true,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: true,
                connectedName: "Hemma",
                knownNames: ["Hemma", "Hemma 5G"],
                saved: [
                    {
                        uuid: "office",
                        ssid: "Office"
                    }
                ],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            },
            "Docked": {
                manager: true,
                adapter: true,
                wired: true,
                dock: true,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: false,
                connectedName: "Hemma",
                knownNames: ["Hemma", "Hemma 5G"],
                saved: [],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            },
            "Connecting": {
                manager: true,
                adapter: true,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: true,
                connectedName: "",
                knownNames: ["Hemma", "Hemma 5G"],
                saved: [],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "Hemma",
                actionKind: "connect"
            },
            "Passphrase": {
                manager: true,
                adapter: true,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: true,
                connectedName: "",
                knownNames: ["Hemma"],
                saved: [],
                passwordSsid: "Telia-7F3A21",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            },
            "Wrong password": {
                manager: true,
                adapter: true,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: true,
                connectedName: "",
                knownNames: ["Hemma"],
                saved: [],
                passwordSsid: "Telia-7F3A21",
                failureSsid: "Telia-7F3A21",
                failureReason: "Wrong password",
                actionSsid: "",
                actionKind: ""
            },
            "Wi-Fi off": {
                manager: true,
                adapter: true,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: false,
                scanner: false,
                connectedName: "",
                knownNames: ["Hemma", "Hemma 5G"],
                saved: [],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            },
            "No adapter": {
                manager: true,
                adapter: false,
                wired: true,
                dock: true,
                frozenOrder: null,
                wifiEnabled: true,
                scanner: false,
                connectedName: "",
                knownNames: [],
                saved: [],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            },
            "No NetworkManager": {
                manager: false,
                adapter: false,
                wired: false,
                dock: false,
                frozenOrder: null,
                wifiEnabled: false,
                scanner: false,
                connectedName: "",
                knownNames: [],
                saved: [],
                passwordSsid: "",
                failureSsid: "",
                failureReason: "",
                actionSsid: "",
                actionKind: ""
            }
        })

    property bool active: false
    property bool manager: true
    property bool adapter: true
    // The dock's Ethernet: present, and connected (wired).
    property bool dock: false
    property bool wired: false
    // Names in the order the list holds once touched; null while it sorts.
    property var frozenOrder: null
    property bool wifiEnabled: true
    // Off, Quickshell lists only known and connected networks.
    property bool scanner: true
    property bool scanning: false
    property string connectedName: "Hemma"
    property var knownNames: ["Hemma", "Hemma 5G"]
    property var saved: [
        {
            uuid: "office",
            ssid: "Office"
        }
    ]
    property string passwordSsid: ""
    property string failureSsid: ""
    property string failureReason: ""
    property string actionSsid: ""
    property string actionKind: ""
    // The panel's expanded Wi-Fi network groups, by key; the others start collapsed. Kept until the shell
    // restarts.
    property var expandedWifiGroups: ({})

    readonly property bool networkManagerAvailable: manager
    readonly property var wifiDevice: manager && adapter ? {
        scannerEnabled: scanner
    } : null
    readonly property var deviceTypes: ({
            Wifi: "wifi",
            Wired: "wired"
        })
    readonly property var wifiNetworks: {
        const visible = wifiDevice && wifiEnabled ? all.filter(network => scanner || network.known || network.connected) : [];
        return frozenOrder ? Model.orderWifiNetworks(frozenOrder, visible) : Model.sortWifiNetworks(visible);
    }
    readonly property var outOfRangeWifi: wifiDevice && wifiEnabled ? Model.outOfRangeWifi(saved, wifiNetworks) : []
    readonly property var connectedWifiNetwork: Model.findConnectedWifiNetwork(wifiNetworks)
    readonly property string kind: wired ? "ethernet" : connectedWifiNetwork ? "wifi" : "disconnected"
    readonly property string icon: Model.connectionIcon(kind, connectedWifiNetwork ? Model.wifiSignal(connectedWifiNetwork) : -1)
    readonly property var networkDevices: {
        const devices = [];
        if (!manager)
            return devices;
        // Quickshell's order: the built-in port (no cable), Wi-Fi, the dock.
        devices.push({
            name: "enp0s31f6",
            type: "Ethernet",
            kind: deviceTypes.Wired,
            connected: false,
            hasLink: false,
            ip: ""
        });
        if (adapter)
            devices.push({
                name: "wlp0s20f3",
                type: "Wi-Fi",
                kind: deviceTypes.Wifi,
                connected: connectedWifiNetwork !== null,
                hasLink: false,
                ip: connectedWifiNetwork ? "192.168.1.23" : ""
            });
        if (dock)
            devices.push({
                name: "enp0s20f0u2u3",
                type: "Ethernet",
                kind: deviceTypes.Wired,
                connected: wired,
                hasLink: true,
                ip: wired ? "10.2.0.65" : ""
            });
        return devices;
    }
    readonly property bool busy: actionKind !== ""
    readonly property bool hasConnection: kind !== "disconnected"
    readonly property var connection: !hasConnection ? {
        iface: "",
        ip: "",
        gateway: ""
    } : wired ? {
        iface: "enp0s20f0u2u3",
        ip: "10.2.0.65",
        gateway: "10.2.0.1"
    } : {
        iface: "wlp0s20f3",
        ip: "192.168.1.23",
        gateway: "192.168.1.1"
    }
    // Docked, the Ethernet carries the traffic and Wi-Fi idles, still answering pings.
    readonly property var details: {
        const result = {};
        if (wired)
            result["enp0s20f0u2u3"] = detail("10.2.0.65", "10.2.0.1", 241300, 15200, 1820433011, 90211873, 9, 1);
        if (connectedWifiNetwork)
            result["wlp0s20f3"] = wired ? detail("192.168.1.23", "192.168.1.1", 120, 0, 3381202, 401330, 15, 3) : detail("192.168.1.23", "192.168.1.1", 182400, 9100, 494471049, 12908299, 13, 2);
        return result;
    }

    function detail(ip, gateway, receiving, sending, rx, tx, ping, gatewayPing) {
        return {
            ip: ip,
            gateway: gateway,
            transfer: {
                rxBytes: rx,
                txBytes: tx,
                receivingRate: receiving,
                sendingRate: sending
            },
            ping: {
                samples: [ping],
                latency: ping,
                packetLoss: 0
            },
            gatewayPing: {
                samples: [gatewayPing],
                latency: gatewayPing,
                packetLoss: 0
            }
        };
    }

    function detailsFor(iface) {
        return details[iface] || null;
    }

    onConnectedNameChanged: syncNetworks()
    onKnownNamesChanged: syncNetworks()
    Component.onCompleted: syncNetworks()

    function syncNetworks() {
        for (const network of all) {
            network.connected = network.name === connectedName;
            network.known = knownNames.indexOf(network.name) >= 0;
        }
    }

    function deviceTypeName(device) {
        return device.type;
    }

    function deviceState(device) {
        if (device.kind === deviceTypes.Wired && !device.hasLink)
            return "No cable";
        return device.connected ? "Connected" : device.kind === deviceTypes.Wifi && !wifiEnabled ? "Unavailable" : "Disconnected";
    }

    function freezeOrder() {
        if (!frozenOrder)
            frozenOrder = wifiNetworks.slice();
    }

    function toggleWifiGroup(key) {
        const next = Object.assign({}, expandedWifiGroups);
        next[key] = !next[key];
        expandedWifiGroups = next;
    }

    function wifiStatus(network) {
        return Model.wifiStatus(network, actionSsid, actionKind);
    }

    function wifiAction(network) {
        return Model.wifiAction(network, actionSsid, securities.Open, securities.Owe);
    }

    function wifiSecured(network) {
        return Model.requiresCredentials(network.security, securities.Open, securities.Owe);
    }

    function join(ssid) {
        passwordSsid = "";
        failureSsid = "";
        failureReason = "";
        if (knownNames.indexOf(ssid) < 0)
            knownNames = knownNames.concat([ssid]);
        connectedName = ssid;
    }

    function activate(network) {
        if (!network || busy)
            return;
        if (network.connected)
            connectedName = "";
        else if (wifiSecured(network) && !network.known)
            passwordSsid = network.name;
        else
            join(network.name);
    }

    function connectWithPassphrase(ssid, passphrase) {
        join(ssid);
    }

    function forget(ssid) {
        knownNames = knownNames.filter(name => name !== ssid);
    }

    function forgetSaved(uuid) {
        saved = saved.filter(entry => entry.uuid !== uuid);
    }

    function toggleWifi() {
        if (wifiDevice)
            wifiEnabled = !wifiEnabled;
    }

    component Network: QtObject {
        property string name
        property real signalStrength
        property string security
        property bool connected: false
        property bool known: false
    }
}
