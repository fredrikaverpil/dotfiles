import QtQuick

// A keycap per key, as style.md draws keys.
Row {
    id: caps

    required property var shell
    property var keys: []
    property real fontSize: 12

    spacing: 3

    Repeater {
        model: caps.keys

        // The dim fill shows as an outline with a thicker bottom edge.
        Rectangle {
            required property string modelData

            width: label.implicitWidth + 10
            height: label.implicitHeight + 5
            radius: 3
            color: caps.shell.palette.dim

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                anchors.bottomMargin: 2
                radius: 2
                color: caps.shell.palette.bg
            }

            Text {
                id: label
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -0.5
                color: caps.shell.palette.off
                font.family: Fonts.mono
                font.pixelSize: caps.fontSize
                text: parent.modelData
            }
        }
    }
}
