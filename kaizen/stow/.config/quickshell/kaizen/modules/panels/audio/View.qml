import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The panel, or the gallery's stand-in.
    required property var audio

    property int cursor: -1

    readonly property int cardWidth: 480
    readonly property int cardHeight: 140 + audio.sinks.length * 38
    readonly property bool keyNavigation: false

    width: parent ? parent.width : 0
    spacing: 8

    function reset() {
        cursor = -1;
        keys.forceActiveFocus();
    }

    function adjust(delta) {
        if (cursor < 0)
            audio.setVolume(audio.volume + delta);
    }

    function moveCursor(delta) {
        cursor = Math.max(-1, Math.min(audio.sinks.length - 1, cursor + delta));
    }

    function activate() {
        if (cursor < 0)
            audio.toggleMute();
        else
            audio.setDefault(audio.sinks[cursor]);
    }

    // The slider and device rows need one cursor; Ui.Panel's focus chain cannot express slider adjustment.
    Item {
        id: keys
        width: 0
        height: 0
        focus: true

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape)
                root.audio.close();
            else if (event.key === Qt.Key_Down || event.text === "j")
                root.moveCursor(1);
            else if (event.key === Qt.Key_Up || event.text === "k")
                root.moveCursor(-1);
            else if (event.key === Qt.Key_Right || event.text === "l")
                root.adjust(0.05);
            else if (event.key === Qt.Key_Left || event.text === "h")
                root.adjust(-0.05);
            else if (event.text === "m")
                root.audio.toggleMute();
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
        text: "Audio"
    }

    Text {
        width: parent.width
        elide: Text.ElideRight
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: root.audio.sink ? root.audio.label(root.audio.sink) + " · " + Math.round(root.audio.volume * 100) + "%" : "No output"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Rectangle {
        id: slider

        width: parent.width
        height: 38
        radius: 4
        color: "transparent"
        border.color: root.cursor < 0 ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1

        Text {
            id: sliderIcon
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 16
            text: root.audio.icon
        }

        Rectangle {
            id: track
            anchors.left: sliderIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: root.shell.palette.dim

            Rectangle {
                width: parent.width * root.audio.volume
                height: parent.height
                radius: parent.radius
                color: root.audio.muted ? root.shell.palette.off : root.shell.palette.fg
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -12
                hoverEnabled: true
                onEntered: root.cursor = -1
                onPositionChanged: function (mouse) {
                    if (pressed)
                        root.audio.setVolume(mouse.x / width);
                }
                onPressed: function (mouse) {
                    root.audio.setVolume(mouse.x / width);
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            onEntered: root.cursor = -1
        }
    }

    Repeater {
        model: root.audio.sinks

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
                anchors.right: mark.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: root.audio.label(modelData)
            }

            Text {
                id: mark
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: modelData === root.audio.sink ? "󰄬" : ""
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.cursor = index
                onClicked: root.audio.setDefault(modelData)
            }
        }
    }
}
