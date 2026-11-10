import QtQuick
import Quickshell
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
    readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
    readonly property var connectedWifiNetwork: findConnectedWifiNetwork()
    readonly property string kind: wiredDevice && wiredDevice.connected ? "ethernet" : connectedWifiNetwork ? "wifi" : "disconnected"
    readonly property int signalStrength: connectedWifiNetwork ? Math.round(Number(connectedWifiNetwork.signalStrength || 0) * 100) : -1
    readonly property string icon: Model.connectionIcon(kind, signalStrength)
    readonly property bool wifiEnabled: Networking.wifiEnabled

    property var wifiNetworks: []
    // Saved connections, including ones out of range that Quickshell does not list.
    property var savedWifi: []
    readonly property var outOfRangeWifi: Model.outOfRangeWifi(savedWifi, wifiNetworkObjects)
    property var ipAddresses: ({})
    property var scannerDevice: null
    property var actionNetwork: null
    property string actionSsid: ""
    property string actionKind: ""
    property string passwordSsid: ""
    property string failureSsid: ""
    property string failureReason: ""
    property bool scanning: false
    // The internet's route: `ip route get 1.1.1.1`.
    property var connection: ({
            iface: "",
            ip: "",
            gateway: ""
        })
    // Default gateway per iface.
    property var gateways: ({})
    // Per iface: ip, gateway, transfer, ping (Cloudflare) and gatewayPing (Model.deviceDetails).
    property var details: ({})
    // Connected devices, and the route's iface when it is none of them (a VPN's).
    readonly property var detailIfaces: {
        const ifaces = [];
        for (const device of networkDevices)
            if (device && device.connected && device.name)
                ifaces.push(device.name);
        if (connection.iface && ifaces.indexOf(connection.iface) < 0)
            ifaces.push(connection.iface);
        return ifaces;
    }

    readonly property bool busy: actionKind !== ""
    readonly property bool hasConnection: connection.iface !== ""

    function actionState() {
        return {
            actionNetwork: actionNetwork,
            actionSsid: actionSsid,
            actionKind: actionKind,
            passwordSsid: passwordSsid,
            failureSsid: failureSsid,
            failureReason: failureReason
        };
    }

    function applyActionState(state) {
        actionNetwork = state.actionNetwork;
        actionSsid = state.actionSsid;
        actionKind = state.actionKind;
        passwordSsid = state.passwordSsid;
        failureSsid = state.failureSsid;
        failureReason = state.failureReason;
    }

    function findDevice(type) {
        return Model.findDevice(networkDevices, type);
    }

    function findConnectedWifiNetwork() {
        return Model.findConnectedWifiNetwork(wifiNetworkObjects);
    }

    function networkForSsid(ssid) {
        return Model.networkForSsid(wifiNetworkObjects, ssid);
    }

    function syncWifiNetworks() {
        var ordered = Model.orderWifiNetworks(wifiNetworks, wifiNetworkObjects);
        if (!Model.sameWifiNetworks(ordered, wifiNetworks))
            wifiNetworks = ordered;
        checkActionCompletion();
    }

    function setScannerEnabled(enabled) {
        var nextDevice = active ? wifiDevice : null;
        if (scannerDevice && scannerDevice !== nextDevice)
            scannerDevice.scannerEnabled = false;
        scannerDevice = nextDevice;
        if (scannerDevice)
            scannerDevice.scannerEnabled = enabled;
    }

    // Quickshell lists only known and connected networks while the scanner is off. Once on,
    // it stays on until the panel closes, or found networks would vanish again.
    function scan() {
        if (!wifiDevice || !active)
            return;
        scanning = true;
        setScannerEnabled(true);
        scanFinished.restart();
    }

    function refresh() {
        syncWifiNetworks();
        if (!ipAddressProcess.running)
            ipAddressProcess.running = true;
        if (!routeProcess.running)
            routeProcess.running = true;
        if (!defaultRoutesProcess.running)
            defaultRoutesProcess.running = true;
        if (!linkStatsProcess.running)
            linkStatsProcess.running = true;
    }

    function updateRoute(raw) {
        connection = Model.parseRoute(raw);
    }

    function updateDetails(rawStats) {
        details = Model.deviceDetails(details, detailIfaces, ipAddresses, gateways, Model.parseLinkStats(rawStats), Date.now() / 1000);
    }

    function recordPing(iface, which, key, raw) {
        details = Model.recordDevicePing(details, iface, which, key, raw);
    }

    function detailsFor(iface) {
        return details[iface] || null;
    }

    function setIpAddresses(raw) {
        ipAddresses = Model.parseIpv4Addresses(raw);
    }

    function ipFor(device) {
        return Model.ipFor(device, ipAddresses);
    }

    function deviceTypeName(device) {
        return Model.deviceType(device.type, DeviceType);
    }

    function deviceDetail(device) {
        return Model.deviceDetail(device, ipAddresses, DeviceType, ConnectionState);
    }

    function wifiStatus(network) {
        return Model.wifiStatus(network, actionSsid, actionKind);
    }

    function wifiAction(network) {
        return Model.wifiAction(network, actionSsid, WifiSecurityType.Open, WifiSecurityType.Owe);
    }

    function wifiSecured(network) {
        return Model.requiresCredentials(network.security, WifiSecurityType.Open, WifiSecurityType.Owe);
    }

    function activate(network) {
        if (!network || busy)
            return;
        if (network.connected) {
            disconnect(network.name);
            return;
        }
        if (Model.requiresCredentials(network.security, WifiSecurityType.Open, WifiSecurityType.Owe) && !network.known) {
            passwordSsid = network.name;
            failureSsid = "";
            failureReason = "";
            return;
        }
        connect(network.name);
    }

    function beginAction(kind, network) {
        var next = Model.beginAction(actionState(), kind, network);
        if (!next)
            return false;
        applyActionState(next);
        actionTimeout.restart();
        return true;
    }

    function connect(ssid) {
        var network = networkForSsid(ssid);
        if (beginAction("connect", network))
            network.connect();
    }

    function connectWithPassphrase(ssid, passphrase) {
        if (!passphrase)
            return;
        var network = networkForSsid(ssid);
        if (beginAction("connect", network))
            network.connectWithPsk(passphrase);
    }

    function disconnect(ssid) {
        var network = networkForSsid(ssid);
        if (beginAction("disconnect", network))
            network.disconnect();
    }

    function forget(ssid) {
        var network = networkForSsid(ssid);
        if (beginAction("forget", network))
            network.forget();
    }

    function forgetSaved(uuid) {
        if (busy || forgetSavedProcess.running)
            return;
        forgetSavedProcess.command = ["nmcli", "connection", "delete", "uuid", uuid];
        forgetSavedProcess.running = true;
    }

    function loadSavedWifi() {
        if (!savedWifiProcess.running)
            savedWifiProcess.running = true;
    }

    function clearAction() {
        actionTimeout.stop();
        applyActionState(Model.clearAction(actionState()));
        refresh();
        loadSavedWifi();
    }

    function failAction(reason) {
        var next = Model.failedAction(actionState(), reason, ConnectionFailReason, WifiSecurityType.Open, WifiSecurityType.Owe);
        if (!next)
            return;
        actionTimeout.stop();
        applyActionState(next);
        refresh();
    }

    function checkActionCompletion() {
        if (Model.isActionComplete(actionState()))
            clearAction();
    }

    function connectionFailureReason(reason) {
        return Model.connectionFailureReason(reason, ConnectionFailReason);
    }

    function toggleWifi() {
        if (!networkManagerAvailable || !wifiDevice)
            return;
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    // Null for an iface without details (not connected).
    function detailStatus(iface) {
        const detail = details[iface];
        if (!detail)
            return null;
        const transfer = detail.transfer || {};
        return {
            gateway: detail.gateway,
            receivingRate: detail.transfer ? transfer.receivingRate : null,
            sendingRate: detail.transfer ? transfer.sendingRate : null,
            rxBytes: detail.transfer ? transfer.rxBytes : null,
            txBytes: detail.transfer ? transfer.txBytes : null,
            ping: detail.ping.latency,
            packetLoss: detail.ping.packetLoss,
            gatewayPing: detail.gatewayPing.latency,
            gatewayPacketLoss: detail.gatewayPing.packetLoss
        };
    }

    function status() {
        var devices = [];
        var source = networkDevices || [];
        for (let i = 0; i < source.length; i++) {
            const device = source[i];
            if (!device)
                continue;
            devices.push({
                name: device.name,
                type: deviceTypeName(device),
                state: Model.connectionState(device.state, ConnectionState),
                ip: ipFor(device),
                details: detailStatus(device.name)
            });
        }
        return JSON.stringify({
            kind: kind,
            wifiEnabled: Networking.wifiEnabled,
            devices: devices,
            connection: Object.assign({
                iface: connection.iface,
                ip: connection.ip,
                gateway: connection.gateway
            }, detailStatus(connection.iface) || {})
        });
    }

    onActiveChanged: {
        if (active) {
            // Drop the frozen order so the list is sorted by strength again on open.
            wifiNetworks = [];
            refresh();
            loadSavedWifi();
        } else {
            passwordSsid = "";
            setScannerEnabled(false);
        }
    }

    onWifiDeviceChanged: {
        setScannerEnabled(false);
        syncWifiNetworks();
    }
    onWifiNetworkObjectsChanged: syncWifiNetworks()

    Component.onCompleted: refresh()
    Component.onDestruction: {
        if (scannerDevice)
            scannerDevice.scannerEnabled = false;
    }

    Connections {
        target: root.actionNetwork

        function onConnectedChanged() {
            root.checkActionCompletion();
        }
        function onKnownChanged() {
            root.checkActionCompletion();
        }
        function onStateChangingChanged() {
            root.checkActionCompletion();
        }
        function onConnectionFailed(reason) {
            root.failAction(reason);
        }
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
        id: savedWifiProcess
        command: ["sh", "-c", "nmcli -t -f connection.uuid,802-11-wireless.ssid connection show" + " $(nmcli -g UUID,TYPE connection show | awk -F: '$2 == \"802-11-wireless\" { print $1 }')"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.savedWifi = Model.parseSavedWifi(text)
        }
    }

    Process {
        id: forgetSavedProcess
        onExited: root.loadSavedWifi()
    }

    Process {
        id: defaultRoutesProcess
        command: ["ip", "-j", "route", "show", "default"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.gateways = Model.parseDefaultRoutes(text)
        }
    }

    Process {
        id: linkStatsProcess
        command: ["ip", "-j", "-s", "link", "show"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateDetails(text)
        }
    }

    // Each iface pings Cloudflare and its gateway through itself, so a standby card shows its own.
    Variants {
        model: root.active ? root.detailIfaces : []

        Scope {
            id: pinger

            required property string modelData
            readonly property string gateway: {
                const detail = root.details[modelData];
                return detail ? detail.gateway : "";
            }

            Process {
                id: internetPing
                command: ["ping", "-n", "-I", pinger.modelData, "-c", "1", "-W", "1", "1.1.1.1"]
                stdout: StdioCollector {
                    waitForEnd: true
                    onStreamFinished: root.recordPing(pinger.modelData, "ping", pinger.modelData, text)
                }
            }

            Process {
                id: gatewayPing
                // The gateway it was started for: a reply after the gateway changed is dropped.
                property string key: ""
                stdout: StdioCollector {
                    waitForEnd: true
                    onStreamFinished: root.recordPing(pinger.modelData, "gatewayPing", gatewayPing.key, text)
                }
            }

            Timer {
                interval: 1500
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: {
                    if (!internetPing.running)
                        internetPing.running = true;
                    if (pinger.gateway && !gatewayPing.running) {
                        gatewayPing.key = pinger.modelData + " " + pinger.gateway;
                        gatewayPing.command = ["ping", "-n", "-I", pinger.modelData, "-c", "1", "-W", "1", pinger.gateway];
                        gatewayPing.running = true;
                    }
                }
            }
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
            root.scanning = false;
            root.syncWifiNetworks();
        }
    }

    Timer {
        id: actionTimeout
        interval: 30000
        repeat: false
        onTriggered: root.failAction(ConnectionFailReason.Unknown)
    }
}
