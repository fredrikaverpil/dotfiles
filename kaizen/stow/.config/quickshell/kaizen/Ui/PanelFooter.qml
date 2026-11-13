import QtQuick

// A panel's own keys, each a keycap and what it does, and at the right its children: the buttons
// acting on the whole panel (style.md › Panels). A note, such as the data's credit, takes a line
// of its own under them. A panel hides the footer, not its only button, which would leave it empty.
Item {
    id: footer

    required property var shell
    // [{ keys: ["m"], label: "mute" }, ...]
    property var entries: []
    property string note: ""
    default property alias buttons: buttonRow.data

    width: parent ? parent.width : 0
    readonly property real rowHeight: Math.max(keys.implicitHeight, buttonRow.implicitHeight)
    implicitHeight: rowHeight + (noteText.visible ? (rowHeight > 0 ? 8 : 0) + noteText.implicitHeight : 0)

    Text {
        id: noteText

        visible: footer.note !== ""
        width: footer.width
        anchors.bottom: parent.bottom
        wrapMode: Text.WordWrap
        color: footer.shell.palette.off
        font.family: Fonts.mono
        font.pixelSize: 12
        text: footer.note
    }

    Row {
        id: keys

        height: footer.rowHeight
        spacing: 16

        Repeater {
            model: footer.entries

            delegate: Row {
                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Keycaps {
                    anchors.verticalCenter: parent.verticalCenter
                    shell: footer.shell
                    keys: parent.modelData.keys
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: footer.shell.palette.off
                    font.family: Fonts.mono
                    font.pixelSize: 12
                    text: parent.modelData.label
                }
            }
        }
    }

    Row {
        id: buttonRow

        anchors.right: parent.right
        height: footer.rowHeight
        spacing: 8
    }
}
