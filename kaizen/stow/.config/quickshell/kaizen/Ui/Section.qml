import QtQuick

// A panel section: a heading, with an optional value or control at its right, ruled underneath, above its
// content.
Column {
    id: section

    required property var shell
    required property string title
    property string value: ""
    // Drawn at the heading's right in place of the value, such as a device's power button.
    property Component control: null

    width: parent ? parent.width : 0
    spacing: 8

    Column {
        width: parent.width
        spacing: 4

        Item {
            width: parent.width
            height: Math.max(titleText.implicitHeight, controlLoader.height)

            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                color: section.shell.palette.fg
                font.family: Fonts.mono
                font.pixelSize: 14
                text: section.title
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: section.control === null
                color: section.shell.palette.off
                font.family: Fonts.mono
                font.pixelSize: 14
                text: section.value
            }

            Loader {
                id: controlLoader
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: section.control
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: section.shell.palette.dim
        }
    }
}
