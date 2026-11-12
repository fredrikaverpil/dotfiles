import QtQuick

// A panel's own keys, each a keycap and what it does, or a fixed note in their place, and at the
// right its children: the buttons acting on the whole panel (style.md › Panels).
Item {
    id: footer

    required property var shell
    // [{ keys: ["m"], label: "mute" }, ...]
    property var entries: []
    // Shown when there are no entries, such as the data's credit; wraps beside the buttons.
    property string note: ""
    default property alias buttons: buttonRow.data

    width: parent ? parent.width : 0
    implicitHeight: Math.max(keys.implicitHeight, noteText.visible ? noteText.implicitHeight : 0, buttonRow.implicitHeight)
    // The row's width, not visibleChildren, which stays empty while the footer is hidden. A hidden
    // footer's buttons count as hidden too, so one that starts hidden never shows: to hide the only
    // button, hide the footer.
    visible: entries.length > 0 || note !== "" || buttonRow.implicitWidth > 0

    Text {
        id: noteText

        visible: footer.entries.length === 0 && footer.note !== ""
        width: Math.max(0, footer.width - buttonRow.implicitWidth - 16)
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.WordWrap
        color: footer.shell.palette.off
        font.family: Fonts.mono
        font.pixelSize: 12
        text: footer.note
    }

    Row {
        id: keys

        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Repeater {
            model: footer.entries

            delegate: Row {
                required property var modelData

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
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
