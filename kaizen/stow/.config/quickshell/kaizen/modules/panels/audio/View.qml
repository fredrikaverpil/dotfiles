import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The panel.
    required property var audio

    readonly property int cardWidth: 400
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 24

    function reset() {
        Qt.callLater(() => {
            const first = slider.visible ? slider : rows.itemAt(0);
            if (first)
                first.forceActiveFocus();
        });
    }

    Column {
        width: parent.width
        spacing: 16

        Ui.PanelHeader {
            shell: root.shell
            title: "Audio"
        }

        Ui.PanelSlider {
            id: slider
            visible: !!root.audio.sink
            shell: root.shell
            value: root.audio.volume
            valueText: Math.round(root.audio.volume * 100) + "%"
            off: root.audio.muted
            icon: root.audio.icon
            iconColor: root.audio.muted ? root.shell.palette.rose : root.shell.palette.fg
            onMoved: value => root.audio.setVolume(value)
            onStepped: direction => root.audio.setVolume(root.audio.volume + 0.05 * direction)
            Keys.onReturnPressed: root.audio.toggleMute()
            Keys.onEnterPressed: root.audio.toggleMute()
            Keys.onSpacePressed: root.audio.toggleMute()
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Output"

        Column {
            width: parent.width
            spacing: 4

            Text {
                visible: root.audio.sinks.length === 0
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: "No devices"
            }

            Repeater {
                id: rows
                model: root.audio.sinks

                delegate: Ui.RadioRow {
                    required property var modelData

                    width: root.width
                    shell: root.shell
                    label: root.audio.label(modelData)
                    chosen: modelData === root.audio.sink
                    onActivated: root.audio.setDefault(modelData)
                }
            }
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            shell: root.shell
            label: "Audio settings…"
            onActivated: root.audio.openSettings()
        }
    }
}
