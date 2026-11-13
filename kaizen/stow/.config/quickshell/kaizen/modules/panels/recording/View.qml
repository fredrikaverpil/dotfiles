import QtQuick

import "../../services/recording/RecordingModel.js" as Model
import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    required property var service

    // On each time the panel opens; a recording holds DnD on until it ends.
    property bool dnd: true

    readonly property int cardWidth: 400
    readonly property bool keyNavigation: true

    signal recordRequested

    width: parent ? parent.width : 0
    spacing: 24

    function reset() {
        dnd = true;
    }

    Ui.PanelHeader {
        shell: root.shell
        title: "Recording"
        value: !root.service.busy ? "" : root.service.countdown > 0 ? String(root.service.countdown) : Model.elapsed(root.service.seconds)
        valueColor: root.service.paused ? root.shell.palette.off : root.shell.palette.rose
        subtitle: root.service.paused ? "Paused" : "Saved to " + root.service.shownDirectory
    }

    // The options are fixed once recording starts, so they hide while busy.
    Ui.Section {
        visible: !root.service.busy
        shell: root.shell

        Cycler {
            label: "Source"
            values: root.service.monitorOptions
            labels: root.service.monitors.concat(["Region"])
            value: root.service.activeMonitor
            onPicked: value => root.service.monitor = value
        }

        Cycler {
            visible: root.service.cameraSupported
            label: "Camera"
            values: root.service.cameraOptions
            labels: ["Off"].concat(root.service.cameras.map(entry => entry.name))
            value: root.service.activeCamera
            onPicked: value => root.service.camera = value
        }

        // Only the Camera row above hides this one, so it never hides while focused.
        Cycler {
            visible: root.service.activeCamera !== ""
            label: "Camera size"
            values: Model.cameraFractions
            labels: Model.cameraFractions.map(value => Math.round(value * 100) + "%")
            value: root.service.cameraFraction
            onPicked: value => root.service.cameraFraction = value
        }

        Cycler {
            label: "Microphone"
            values: root.service.micOptions
            labels: ["Off", "Default input"].concat(root.service.mics.map(node => node.description || node.nickname || node.name))
            value: root.service.activeMic
            onPicked: value => root.service.mic = value
        }

        OnOff {
            label: "Desktop audio"
            value: root.service.desktop
            onPicked: value => root.service.desktop = value
        }

        OnOff {
            label: "Pause notifications"
            value: root.dnd
            onPicked: value => root.dnd = value
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            visible: !root.service.busy
            shell: root.shell
            label: "Record"
            onActivated: root.recordRequested()
        }

        Ui.PanelButton {
            visible: root.service.busy
            // The countdown has nothing to pause.
            available: root.service.recording
            shell: root.shell
            label: root.service.paused ? "Resume" : "Pause"
            onActivated: root.service.togglePause()
        }

        Ui.PanelButton {
            visible: root.service.busy
            shell: root.shell
            label: "Stop"
            onActivated: root.service.stop()
        }
    }

    // A setting with many values: its label, then `‹ value ›`; h/l, Enter, Space or a click step it, a
    // right-click back.
    component Cycler: Ui.PanelRow {
        id: cycler

        property string label: ""
        property var values: []
        property var labels: []
        property var value

        signal picked(var value)

        function step(delta) {
            picked(Model.step(values, value, delta));
        }

        width: root.width
        shell: root.shell
        onActivated: cycler.step(1)
        // Up/down fall through to the panel's focus chain.
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Right || event.text === "l")
                cycler.step(1);
            else if (event.key === Qt.Key_Left || event.text === "h")
                cycler.step(-1);
            else
                return;
            event.accepted = true;
        }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: cycler.label
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width * 0.65)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "‹ " + (cycler.labels[cycler.values.indexOf(cycler.value)] || "—") + " ›"
        }

        // A left click passes through to the row's own area.
        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            acceptedButtons: Qt.RightButton
            onClicked: cycler.step(-1)
        }
    }

    // An On/Off setting: its label, then a segmented control.
    component OnOff: Item {
        id: toggle

        property string label: ""
        property bool value: false

        signal picked(bool value)

        width: root.width
        implicitHeight: segments.implicitHeight

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: toggle.label
        }

        Ui.SegmentedControl {
            id: segments
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: implicitWidth
            shell: root.shell
            options: [
                {
                    label: "On",
                    value: true
                },
                {
                    label: "Off",
                    value: false
                },
            ]
            current: toggle.value
            onPicked: value => toggle.picked(value)
        }
    }
}
