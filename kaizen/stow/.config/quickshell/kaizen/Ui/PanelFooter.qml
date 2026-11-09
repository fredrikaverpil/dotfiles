import QtQuick

// A panel's own keys, each a keycap and what it does (style.md › Panels).
Row {
    id: footer

    required property var shell
    // [{ keys: ["m"], label: "mute" }, ...]
    property var entries: []

    visible: entries.length > 0
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
