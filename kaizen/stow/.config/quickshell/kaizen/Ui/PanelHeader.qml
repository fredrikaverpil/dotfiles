import QtQuick

// A panel's title with its one key value, over a subtitle (style.md › Panels).
Item {
    id: header

    required property var shell
    required property string title
    property string value: ""
    property color valueColor: shell.palette.fg
    property string subtitle: ""
    // A control in the key value's place (bluetooth's power button), centred on both lines.
    default property alias control: slot.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(lines.implicitHeight, slot.height)

    Column {
        id: lines
        width: parent.width - (slot.width > 0 ? slot.width + 8 : 0)
        spacing: 4

        Item {
            width: parent.width
            height: titleText.implicitHeight

            Text {
                id: titleText
                color: header.shell.palette.fg
                font.family: Fonts.mono
                font.pixelSize: 16
                text: header.title
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: header.valueColor
                font.family: Fonts.mono
                font.pixelSize: 16
                text: header.value
            }
        }

        Text {
            width: parent.width
            visible: header.subtitle !== ""
            elide: Text.ElideRight
            color: header.shell.palette.off
            font.family: Fonts.mono
            font.pixelSize: 14
            text: header.subtitle
        }
    }

    // A Row, so a hidden control takes no width.
    Row {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
