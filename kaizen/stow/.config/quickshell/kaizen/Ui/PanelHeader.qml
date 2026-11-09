import QtQuick

// A panel's title with its one key value, over a subtitle (style.md › Panels).
Column {
    id: header

    required property var shell
    required property string title
    property string value: ""
    property color valueColor: shell.palette.fg
    property string subtitle: ""

    width: parent ? parent.width : 0
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
