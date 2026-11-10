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
        }
    ]
    readonly property var metrics: ({
            connection: {
                iface: "wlp0s20f3",
                ip: "192.168.1.23",
                gateway: "192.168.1.1",
                rxBytes: 494471049,
                txBytes: 12908299
            },
            transfer: {
                receivingRate: 182400,
                sendingRate: 9100
            },
            ping: {
                samples: [12, 14, 13],
                latency: 13,
                packetLoss: 0
            },
            gatewayPing: {
                samples: [2, 3, 2],
                latency: 2,
                packetLoss: 0
            }
        })
    readonly property var scenarios: ({
            "Wi-Fi": {
                manager: true,
                adapter: true,
                wired: false,
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
    property bool wired: false
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

    readonly property bool networkManagerAvailable: manager
    readonly property var wifiDevice: manager && adapter ? {
        scannerEnabled: scanner
    } : null
    readonly property var wifiNetworks: wifiDevice && wifiEnabled ? all.filter(network => scanner || network.known || network.connected) : []
    readonly property var outOfRangeWifi: wifiDevice && wifiEnabled ? Model.outOfRangeWifi(saved, wifiNetworks) : []
    readonly property var connectedWifiNetwork: Model.findConnectedWifiNetwork(wifiNetworks)
    readonly property string kind: wired ? "ethernet" : connectedWifiNetwork ? "wifi" : "disconnected"
    readonly property string icon: Model.connectionIcon(kind, connectedWifiNetwork ? Model.wifiSignal(connectedWifiNetwork) : -1)
    readonly property var networkDevices: {
        const devices = [];
        if (!manager)
            return devices;
        if (wired)
            devices.push({
                name: "enp0s20f0u2u3",
                type: "Ethernet",
                detail: "Connected · 10.2.0.65"
            });
        if (adapter)
            devices.push({
                name: "wlp0s20f3",
                type: "Wi-Fi",
                detail: connectedWifiNetwork ? "Connected · 192.168.1.23" : "Disconnected"
            });
        return devices;
    }
    readonly property bool busy: actionKind !== ""
    readonly property bool hasConnection: kind !== "disconnected"
    readonly property var connection: hasConnection ? (wired ? Object.assign({}, metrics.connection, {
            iface: "enp0s20f0u2u3",
            ip: "10.2.0.65",
            gateway: "10.2.0.1"
        }) : metrics.connection) : {
        iface: "",
        ip: "",
        gateway: "",
        rxBytes: null,
        txBytes: null
    }
    readonly property var transfer: metrics.transfer
    readonly property var ping: metrics.ping
    readonly property var gatewayPing: metrics.gatewayPing
    readonly property bool hasTransfer: hasConnection
    readonly property bool hasPing: hasConnection
    readonly property bool hasGatewayPing: hasConnection

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

    function deviceDetail(device) {
        return device.detail;
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

    function scan() {
        scanning = true;
        scanner = true;
        scanDone.restart();
    }

    property Timer scanDone: Timer {
        interval: 1500
        onTriggered: fake.scanning = false
    }

    component Network: QtObject {
        property string name
        property real signalStrength
        property string security
        property bool connected: false
        property bool known: false
    }
}
