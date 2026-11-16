import QtQuick
import Quickshell
import Quickshell.Wayland

// A brief card for a value a key changed, centred. No screen is set, so the compositor maps it on the focused output.
PanelWindow {
    id: root

    required property var shell
    property string icon: ""
    // From 0 to 1, on the track.
    property real value: 0
    // Muted or off: the fill turns `off`.
    property bool off: false
    // Shown instead of the track and value.
    property string text: ""

    function show() {
        visible = true;
        hide.restart();
    }

    visible: false
    implicitWidth: 320 * shell.textScale
    implicitHeight: 48 * shell.textScale
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 320
        height: 48
        scale: root.shell.textScale
        radius: 8
        color: root.shell.palette.bg
        border.color: root.shell.palette.dim
        border.width: 1

        Text {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 18
            text: root.icon
        }

        Text {
            id: value
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text === ""
            color: root.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 13
            text: Math.round(root.value * 100) + "%"
        }

        Rectangle {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: value.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text === ""
            height: 6
            radius: 3
            color: root.shell.palette.dim

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: parent.radius
                color: root.off ? root.shell.palette.off : root.shell.palette.fg
            }
        }

        Text {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            color: root.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 13
            text: root.text
        }
    }
}
