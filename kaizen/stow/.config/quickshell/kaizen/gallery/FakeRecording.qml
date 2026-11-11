import QtQuick

import "../modules/services/recording/RecordingModel.js" as Model

// The recording service's members the view and bar button read, without a recorder.
QtObject {
    id: fake

    readonly property var laptopMic: ({
            name: "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source",
            description: "Meteor Lake-P HD Audio Controller Digital Microphone"
        })
    readonly property var idle: ({
            monitors: ["eDP-1"],
            cameraSupported: true,
            cameras: [
                {
                    name: "Integrated Camera",
                    path: "/dev/video0"
                }
            ],
            mics: [laptopMic],
            monitor: "",
            camera: "",
            cameraFraction: Model.cameraFraction,
            mic: "default_input",
            desktop: true,
            countdown: 0,
            recording: false,
            paused: false,
            seconds: 0
        })
    readonly property var scenarios: ({
            "Idle": idle,
            "Camera on": Object.assign({}, idle, {
                monitors: ["eDP-1", "DP-1"],
                monitor: "DP-1",
                camera: "/dev/video0"
            }),
            "Several mics": Object.assign({}, idle, {
                mics: [laptopMic,
                    {
                        name: "alsa_input.usb-Shure_MV7-00.analog-stereo",
                        description: "Shure MV7"
                    },
                    {
                        name: "bluez_input.AC_80_0A_12_34_56",
                        description: "WH-1000XM5"
                    }
                ],
                mic: "alsa_input.usb-Shure_MV7-00.analog-stereo"
            }),
            "Countdown": Object.assign({}, idle, {
                countdown: 3
            }),
            "Recording": Object.assign({}, idle, {
                recording: true,
                seconds: 754
            }),
            "Paused": Object.assign({}, idle, {
                recording: true,
                paused: true,
                seconds: 754
            }),
            "No camera support": Object.assign({}, idle, {
                cameraSupported: false
            })
        })

    readonly property string shownDirectory: "~/Videos/Recordings"
    property var monitors: []
    property bool cameraSupported: true
    property var cameras: []
    property var mics: []
    property string monitor: ""
    property string camera: ""
    property real cameraFraction: Model.cameraFraction
    property string mic: "default_input"
    property bool desktop: true
    property int countdown: 0
    property bool recording: false
    property bool paused: false
    property int seconds: 0

    readonly property bool busy: recording || countdown > 0
    readonly property var monitorOptions: monitors.concat(["region"])
    readonly property var cameraOptions: [""].concat(cameraSupported ? cameras.map(entry => entry.path) : [])
    readonly property var micOptions: ["", "default_input"].concat(mics.map(node => node.name))
    readonly property string activeMonitor: Model.pick(monitorOptions, monitor, monitors[0] || "")
    readonly property string activeCamera: Model.pick(cameraOptions, camera, "")
    readonly property string activeMic: Model.pick(micOptions, mic, "default_input")

    function togglePause() {
        if (recording)
            paused = !paused;
    }

    function stop() {
        countdown = 0;
        recording = false;
        paused = false;
        seconds = 0;
    }
}
