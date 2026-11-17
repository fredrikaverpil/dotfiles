import QtQuick
import Quickshell
import Quickshell.Wayland

// A headline, large and centred on every output, fading out after a few seconds: for what a glance from across the
// desk has to catch. A click dismisses it. The caller decides what holds it back.
Scope {
    id: root

    required property var shell
    required property string namespace
    property string headline: ""
    property string detail: ""

    property real level: 0

    signal dismissed

    function show() {
        out.stop();
        fade.restart();
    }

    function dismiss() {
        if (root.level === 0)
            return;
        fade.stop();
        out.restart();
        root.dismissed();
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

    NumberAnimation {
        id: out
        target: root
        property: "level"
        to: 0
        duration: 150
        easing.type: Easing.InQuad
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: root.level > 0
            implicitWidth: card.width * root.shell.textScale
            implicitHeight: card.height * root.shell.textScale
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: root.namespace

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.max(400, content.implicitWidth + 48)
                height: 200
                scale: root.shell.textScale
                opacity: root.level
                radius: 8
                color: root.shell.palette.bg
                border.color: root.shell.palette.dim
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismiss()
                }

                Column {
                    id: content
                    anchors.centerIn: parent
                    spacing: 4

                    // Off the type scale (style.md › Panels › Type): a glance from across the desk has to catch it.
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.shell.palette.fg
                        font.family: Fonts.mono
                        font.pixelSize: 96
                        text: root.headline
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.shell.palette.off
                        font.family: Fonts.mono
                        font.pixelSize: 16
                        text: root.detail
                    }
                }
            }
        }
    }
}
