import QtQuick

// A panel section: a heading, with an optional value at its right, ruled underneath, above its content.
Column {
    id: section

    required property var shell
    required property string title
    property string value: ""

    width: parent ? parent.width : 0
    spacing: 8

    Column {
        width: parent.width
        spacing: 4

        Item {
            width: parent.width
            height: titleText.implicitHeight

            Text {
                id: titleText
                color: section.shell.palette.fg
                font.family: Fonts.mono
                font.pixelSize: 14
                text: section.title
            }

            Text {
                anchors.right: parent.right
                color: section.shell.palette.off
                font.family: Fonts.mono
                font.pixelSize: 14
                text: section.value
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: section.shell.palette.dim
        }
    }
}
