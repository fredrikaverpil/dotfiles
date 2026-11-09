import QtQuick

// A panel section: a heading, ruled underneath, above its content.
Column {
    id: section

    required property var shell
    required property string title

    width: parent ? parent.width : 0
    spacing: 8

    Column {
        width: parent.width
        spacing: 4

        Text {
            color: section.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 14
            text: section.title
        }

        Rectangle {
            width: parent.width
            height: 1
            color: section.shell.palette.dim
        }
    }
}
