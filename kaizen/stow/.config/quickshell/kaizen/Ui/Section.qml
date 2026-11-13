import QtQuick

// A panel section: a rule heading its content, with an optional label at its left and an optional value and
// control at its right, all on one line.
Column {
    id: section

    required property var shell
    property string title: ""
    property string value: ""
    // Drawn at the rule's right, right of the value, such as a device's power button.
    property Component control: null

    width: parent ? parent.width : 0
    spacing: 8

    Item {
        id: heading

        readonly property Item end: section.value !== "" ? valueText : controlLoader
        readonly property bool hasEnd: section.control !== null || section.value !== ""
        // A bare rule keeps no text line: 8 under it, plus the spacing, puts its content 16 under it, as a
        // label's centred rule does.
        readonly property bool bare: section.title === "" && !hasEnd

        width: parent.width
        height: bare ? 9 : Math.max(titleText.implicitHeight, controlLoader.height)

        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            visible: section.title !== ""
            color: section.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: 14
            text: section.title
        }

        Rectangle {
            x: titleText.visible ? titleText.width + 8 : 0
            width: (heading.hasEnd ? heading.end.x - 8 : parent.width) - x
            y: heading.bare ? 0 : Math.round((parent.height - height) / 2)
            height: 1
            color: section.shell.palette.dim
        }

        Text {
            id: valueText
            anchors.right: section.control !== null ? controlLoader.left : parent.right
            anchors.rightMargin: section.control !== null ? 8 : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: section.value !== ""
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
}
