import QtQuick

import "../modules/services/bluetooth/BluetoothModel.js" as Model

// The bluetooth service's members the view and bar button read, without BlueZ.
QtObject {
    id: fake

    // As Quickshell's BluetoothDeviceState.
    readonly property var deviceStates: ({
            Disconnected: 0,
            Connected: 1,
            Disconnecting: 2,
            Connecting: 3
        })
    readonly property list<QtObject> all: [
        Device {
            name: "AirPods Pro"
            icon: "audio-headphones"
        },
        Device {
            name: "HHKB-Hybrid_1"
            icon: "input-keyboard"
        },
        Device {
            name: "Logi M650"
            icon: "input-mouse"
        },
        Device {
            name: "MX Anywhere 3S"
            icon: "input-mouse"
        },
        Device {
            name: "WH-1000XM4"
            icon: "audio-headset"
        }
    ]
    readonly property var scenarios: ({
            "Connected": {
                available: true,
                powered: true,
                paired: true,
                states: {
                    "AirPods Pro": deviceStates.Connected,
                    "MX Anywhere 3S": deviceStates.Connected
                },
                levels: {
                    "AirPods Pro": 0.8,
                    "MX Anywhere 3S": 0.12
                }
            },
            "Connecting": {
                available: true,
                powered: true,
                paired: true,
                states: {
                    "AirPods Pro": deviceStates.Connected,
                    "WH-1000XM4": deviceStates.Connecting
                },
                levels: {
                    "AirPods Pro": 0.8
                }
            },
            "No battery": {
                available: true,
                powered: true,
                paired: true,
                states: {
                    "HHKB-Hybrid_1": deviceStates.Connected
                },
                levels: {}
            },
            "None connected": {
                available: true,
                powered: true,
                paired: true,
                states: {},
                levels: {}
            },
            "No devices": {
                available: true,
                powered: true,
                paired: false,
                states: {},
                levels: {}
            },
            "Off": {
                available: true,
                powered: false,
                paired: true,
                states: {},
                levels: {}
            },
            "No adapter": {
                available: false,
                powered: false,
                paired: false,
                states: {},
                levels: {}
            }
        })

    property bool available: true
    property bool powered: true
    property bool paired: true
    // Device name to state and to battery (0-1); a device left out is disconnected, without one.
    property var states: ({})
    property var levels: ({})

    readonly property var devices: Model.pairedDevices(paired ? all : [])
    readonly property int connectedCount: devices.filter(device => device.connected).length
    readonly property string icon: Model.barIcon(available, powered, connectedCount)
    // As the service's.
    readonly property int lowestBattery: devices.reduce((low, device) => {
        const level = device.connected ? Math.round(battery(device) * 100) : -1;
        return level >= 0 && (low < 0 || level < low) ? level : low;
    }, -1)

    onStatesChanged: {
        for (const device of all)
            device.state = states[device.name] ?? deviceStates.Disconnected;
    }
    onLevelsChanged: {
        for (const device of all)
            device.battery = levels[device.name] ?? -1;
    }

    function togglePower() {
        if (available)
            powered = !powered;
    }

    function battery(device) {
        return device.batteryAvailable ? device.battery : -1;
    }

    function deviceStatus(device) {
        return Model.deviceStatus(device.state, deviceStates, battery(device));
    }

    function deviceAction(device) {
        return Model.deviceAction(device.state, deviceStates);
    }

    function deviceIcon(device) {
        return Model.deviceIcon(device.icon);
    }

    function toggleConnection(device) {
        device.state = device.connected ? deviceStates.Disconnected : deviceStates.Connected;
    }

    component Device: QtObject {
        property string name
        property string icon
        property int state: 0
        property real battery: -1
        readonly property bool paired: true
        readonly property bool connected: state === 1
        readonly property bool batteryAvailable: battery >= 0
    }
}
