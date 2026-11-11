import QtQuick

import "../../services/recording/RecordingModel.js" as Model
import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    required property var service

    // Options are hidden while busy, so the cursor spans the rows and then the actions.
    readonly property var rows: service.busy ? [] : [
        {
            label: "Source",
            values: service.monitorOptions,
            labels: service.monitors.concat(["Region"]),
            value: service.activeMonitor,
            set: value => root.service.monitor = value
        },
        ...(service.cameraSupported ? [
                {
                    label: "Camera",
                    values: service.cameraOptions,
                    labels: ["Off"].concat(service.cameras.map(entry => entry.name)),
                    value: service.activeCamera,
                    set: value => root.service.camera = value
                }
            ] : []),
        // Only the Camera row above can turn this one off, so the cursor never
        // sits on a row the change moves.
        ...(service.activeCamera ? [
                {
                    label: "Camera size",
                    values: Model.cameraFractions,
                    labels: Model.cameraFractions.map(value => Math.round(value * 100) + "%"),
                    value: service.cameraFraction,
                    set: value => root.service.cameraFraction = value
                }
            ] : []),
        {
            label: "Microphone",
            values: service.micOptions,
            labels: ["Off", "Default input"].concat(service.mics.map(node => node.description || node.nickname || node.name)),
            value: service.activeMic,
            set: value => root.service.mic = value
        },
        {
            label: "Desktop audio",
            values: [true, false],
            labels: ["On", "Off"],
            value: service.desktop,
            set: value => root.service.desktop = value
        },
        {
            label: "Do not disturb",
            values: [true, false],
            labels: ["On", "Off"],
            value: root.dnd,
            set: value => root.dnd = value
        },
    ]
    readonly property var actions: service.busy ? [
        {
            label: service.paused ? "Resume" : "Pause",
            run: () => root.service.togglePause()
        },
        {
            label: "Stop",
            run: () => root.service.stop()
        },
    ] : [
        {
            label: "Record",
            run: () => root.recordRequested()
        }
    ]
    readonly property int count: rows.length + actions.length

    property int cursor: 0
    // On each time the panel opens; a recording holds DnD on until it ends.
    property bool dnd: true

    readonly property int cardWidth: 480
    readonly property int cardHeight: 90 + count * 38
    readonly property bool keyNavigation: false

    signal closeRequested
    signal recordRequested

    width: parent ? parent.width : 0
    spacing: 8

    // Record is preselected, so Enter starts with the saved choices.
    function reset() {
        dnd = true;
        cursor = rows.length;
        keys.forceActiveFocus();
    }

    function adjust(delta) {
        const row = rows[cursor];
        if (row)
            row.set(Model.step(row.values, row.value, delta));
    }

    function activate() {
        if (cursor < rows.length)
            adjust(1);
        else
            actions[cursor - rows.length].run();
    }

    function moveCursor(delta) {
        cursor = Math.max(0, Math.min(count - 1, cursor + delta));
    }

    onCountChanged: cursor = Math.min(cursor, count - 1)

    Item {
        id: keys
        width: 0
        height: 0
        focus: true

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape)
                root.closeRequested();
            else if (event.key === Qt.Key_Down || event.text === "j")
                root.moveCursor(1);
            else if (event.key === Qt.Key_Up || event.text === "k")
                root.moveCursor(-1);
            else if (event.key === Qt.Key_Right || event.text === "l")
                root.adjust(1);
            else if (event.key === Qt.Key_Left || event.text === "h")
                root.adjust(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                root.activate();
            else
                return;
            event.accepted = true;
        }
    }

    Text {
        width: parent.width
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 18
        text: "Record"
    }

    Text {
        width: parent.width
        elide: Text.ElideRight
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: root.service.busy ? (root.service.paused ? "Paused · " : "Recording · ") + Model.elapsed(root.service.seconds) : "Saved to ~/Videos"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Repeater {
        model: root.rows

        delegate: Rectangle {
            required property var modelData
            required property int index

            width: root.width
            height: 30
            radius: 4
            color: root.cursor === index ? root.shell.palette.sel : "transparent"
            border.color: root.cursor === index ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: modelData.label
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.6
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: "‹ " + (modelData.labels[modelData.values.indexOf(modelData.value)] || "—") + " ›"
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: root.cursor = index
                onClicked: function (mouse) {
                    root.adjust(mouse.button === Qt.RightButton ? -1 : 1);
                }
            }
        }
    }

    Repeater {
        model: root.actions

        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property int position: root.rows.length + index

            width: root.width
            height: 30
            radius: 4
            color: root.cursor === position ? root.shell.palette.sel : "transparent"
            border.color: root.cursor === position ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1

            Text {
                anchors.centerIn: parent
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: modelData.label
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.cursor = parent.position
                onClicked: parent.modelData.run()
            }
        }
    }
}
