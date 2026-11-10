import QtQuick

import "../modules/services/mirror/MirrorModel.js" as MirrorModel

// The brightness, nightlight and mirror services' and the outputs' members the view reads, in one.
QtObject {
    id: fake

    readonly property var scenarios: ({
            "Laptop": {
                focused: {
                    name: "eDP-1",
                    width: 2880,
                    height: 1800
                },
                names: ["eDP-1"],
                present: true,
                output: "eDP-1",
                percent: 60,
                mode: "off",
                temperature: 6500,
                mirrors: []
            },
            "Docked, mirrored": {
                focused: {
                    name: "DP-1",
                    width: 3840,
                    height: 2160
                },
                names: ["eDP-1", "DP-1"],
                present: true,
                output: "eDP-1",
                percent: 80,
                mode: "off",
                temperature: 6500,
                mirrors: [
                    {
                        source: "DP-1",
                        target: "eDP-1"
                    }
                ]
            },
            "No backlight": {
                focused: {
                    name: "DP-1",
                    width: 3840,
                    height: 2160
                },
                names: ["DP-1"],
                present: false,
                output: "",
                percent: 0,
                mode: "off",
                temperature: 6500,
                mirrors: []
            },
            "Nightlight auto": {
                focused: {
                    name: "eDP-1",
                    width: 2880,
                    height: 1800
                },
                names: ["eDP-1"],
                present: true,
                output: "eDP-1",
                percent: 35,
                mode: "auto",
                temperature: 4000,
                mirrors: []
            },
            "No display": {
                focused: null,
                names: [],
                present: false,
                output: "",
                percent: 0,
                mode: "off",
                temperature: null,
                mirrors: []
            }
        })

    // Outputs.
    property var focused: null
    property var names: []

    // Brightness.
    readonly property int step: 5
    property bool present: false
    property string output: ""
    property int percent: 0

    function set(value) {
        percent = Math.max(0, Math.min(100, Math.round(value)));
    }

    function adjust(delta) {
        set(percent + delta);
    }

    // Nightlight.
    property string mode: "off"
    property var temperature: null

    function setMode(value) {
        mode = value;
        temperature = value === "on" ? 4000 : value === "off" ? 6500 : temperature;
    }

    // Mirror.
    property var mirrors: []
    readonly property bool busy: false

    function sourceOf(target) {
        const mirror = mirrors.find(mirror => mirror.target === target);
        return mirror ? mirror.source : "";
    }

    function canMirror(source, target) {
        return MirrorModel.canMirror(mirrors, source, target);
    }

    function start(source, target) {
        if (canMirror(source, target))
            mirrors = mirrors.filter(mirror => mirror.target !== target).concat([
                {
                    source: source,
                    target: target
                }
            ]);
    }

    function stop(target) {
        mirrors = mirrors.filter(mirror => mirror.target !== target);
    }
}
