import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../../Ui" as Ui

// The time, large and centred on every output, when the hour strikes. Held back under DnD, which is for sharing and
// recording the screen, and while locked or curtained. A strike missed asleep is not shown on resume.
Scope {
    id: root

    required property var shell
    // The timezone panel, whose IPC shows this on demand.
    required property var panel

    property real level: 0

    function strike() {
        if (shell.notifications.doNotDisturb || shell.lock.locked || shell.curtain.active)
            return;
        show();
    }

    function show() {
        fade.restart();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: if (date.getMinutes() === 0)
            root.strike()
    }

    Connections {
        target: root.panel

        function onHourRequested() {
            root.show();
        }
    }

    SequentialAnimation {
        id: fade
        NumberAnimation {
            target: root
            property: "level"
            to: 1
            duration: 200
            easing.type: Easing.OutQuad
        }
        PauseAnimation {
            duration: 3000
        }
        NumberAnimation {
            target: root
            property: "level"
            to: 0
            duration: 600
            easing.type: Easing.InQuad
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.level > 0
            implicitWidth: 400 * root.shell.textScale
            implicitHeight: 200 * root.shell.textScale
            exclusiveZone: 0
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "kaizen-hour"

            Rectangle {
                anchors.centerIn: parent
                width: 400
                height: 200
                scale: root.shell.textScale
                opacity: root.level
                radius: 8
                color: root.shell.palette.bg
                border.color: root.shell.palette.dim
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    // Off the type scale (style.md › Panels › Type): a glance from across the desk has to catch it.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 96
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.shell.palette.off
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 16
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    }
                }
            }
        }
    }
}
