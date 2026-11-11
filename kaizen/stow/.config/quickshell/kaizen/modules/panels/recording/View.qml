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
    readonly property int cardPadding: 16
    readonly property int cardHeight: implicitHeight + 2 * cardPadding
    readonly property bool keyNavigation: true

    signal recordRequested

    width: parent ? parent.width : 0
    spacing: 24

    // Record is preselected, so Enter starts with the saved choices; while recording, Pause; in the
    // countdown, Stop.
    function reset() {
        dnd = true;
        (!service.busy ? recordButton : service.recording ? pauseButton : stopButton).forceActiveFocus();
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
            id: recordButton
            visible: !root.service.busy
            shell: root.shell
            label: "Record"
            onActivated: root.recordRequested()
        }

        Ui.PanelButton {
            id: pauseButton
            visible: root.service.busy
            // The countdown has nothing to pause.
            available: root.service.recording
            shell: root.shell
            label: root.service.paused ? "Resume" : "Pause"
            onActivated: root.service.togglePause()
        }

        Ui.PanelButton {
            id: stopButton
            visible: root.service.busy
            shell: root.shell
            label: "Stop"
            onActivated: root.service.stop()
        }
    }

    // A setting with many values: its label, then `‹ value ›`; h/l, Enter, Space or a click step it.
    component Cycler: Item {
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
        implicitHeight: 28
        activeFocusOnTab: visible || activeFocus
        // Up/down fall through to the panel's focus chain.
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Right || event.text === "l" || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                cycler.step(1);
            else if (event.key === Qt.Key_Left || event.text === "h")
                cycler.step(-1);
            else
                return;
            event.accepted = true;
        }

        // The fill reaches into the card's padding, so the label aligns with the group's rule.
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            radius: 4
            color: cycler.activeFocus ? root.shell.palette.sel : "transparent"
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

        MouseArea {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: cycler.forceActiveFocus()
            onClicked: function (mouse) {
                cycler.step(mouse.button === Qt.RightButton ? -1 : 1);
            }
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
            width: 112
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
