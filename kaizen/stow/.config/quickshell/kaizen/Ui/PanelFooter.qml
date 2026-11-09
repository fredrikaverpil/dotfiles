import QtQuick

// A panel's own keys, each a keycap and what it does, and at the right a button acting on the
// whole panel (style.md › Panels).
Item {
    id: footer

    required property var shell
    // [{ keys: ["m"], label: "mute" }, ...]
    property var entries: []
    // The panel-wide button's label; "" for none.
    property string buttonLabel: ""

    signal buttonActivated

    width: parent ? parent.width : 0
    implicitHeight: Math.max(keys.implicitHeight, button.visible ? button.implicitHeight : 0)
    visible: entries.length > 0 || buttonLabel !== ""

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

    PanelButton {
        id: button

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: footer.buttonLabel !== ""
        shell: footer.shell
        label: footer.buttonLabel
        onActivated: footer.buttonActivated()
    }
}
