import QtQuick

// The audio panel's members the view reads, without PipeWire.
QtObject {
    id: fake

    // Objects, as PipeWire's nodes are: the view tells the default by identity.
    readonly property list<QtObject> devices: [
        FakeDevice {
            name: "Speakers"
        },
        FakeDevice {
            name: "Dock headphones"
        },
        FakeDevice {
            name: "HDMI · DELL U2723QE"
        }
    ]
    readonly property var scenarios: ({
            "Playing": {
                sinks: devices,
                current: 0,
                volume: 0.64,
                muted: false
            },
            "Muted": {
                sinks: devices,
                current: 0,
                volume: 0.64,
                muted: true
            },
            "Headphones": {
                sinks: devices,
                current: 1,
                volume: 0.3,
                muted: false
            },
            "No output": {
                sinks: [],
                current: -1,
                volume: 0,
                muted: false
            }
        })

    property var sinks: devices
    property int current: 0
    property real volume: 0.64
    property bool muted: false
    readonly property var sink: current >= 0 && current < sinks.length ? sinks[current] : null
    // As the panel's.
    readonly property string icon: muted || volume <= 0 ? "󰖁" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"

    function label(node) {
        return node ? node.name : "";
    }

    function setVolume(value) {
        if (sink)
            volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (sink)
            muted = !muted;
    }

    function setDefault(node) {
        for (let i = 0; i < sinks.length; i++) {
            if (sinks[i] === node)
                current = i;
        }
    }

    function openSettings() {
    }

    function close() {
    }
}
