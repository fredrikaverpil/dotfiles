import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The audio service.
    required property var service

    readonly property int cardWidth: 400
    readonly property bool keyNavigation: true

    // Inputs, per-app volumes and profiles are set in pwvucontrol; the panel closes for it.
    signal settingsRequested

    width: parent ? parent.width : 0
    spacing: 24

    Column {
        width: parent.width
        spacing: 16

        Ui.PanelHeader {
            shell: root.shell
            title: "Audio"
        }

        Ui.PanelSlider {
            visible: !!root.service.sink
            shell: root.shell
            value: root.service.volume
            valueText: Math.round(root.service.volume * 100) + "%"
            off: root.service.muted
            icon: root.service.icon
            iconColor: root.service.muted ? root.shell.palette.rose : root.shell.palette.fg
            onMoved: value => root.service.setVolume(value)
            onStepped: direction => root.service.setVolume(root.service.volume + 0.05 * direction)
            Keys.onReturnPressed: root.service.toggleMute()
            Keys.onEnterPressed: root.service.toggleMute()
            Keys.onSpacePressed: root.service.toggleMute()
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Output"

        Column {
            width: parent.width
            spacing: 4

            Text {
                visible: root.service.sinks.length === 0
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: "No devices"
            }

            Repeater {
                model: root.service.sinks

                delegate: Ui.RadioRow {
                    required property var modelData

                    width: root.width
                    shell: root.shell
                    label: root.service.label(modelData)
                    chosen: modelData === root.service.sink
                    onActivated: root.service.setDefault(modelData)
                }
            }
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            shell: root.shell
            label: "Audio settings…"
            onActivated: root.settingsRequested()
        }
    }
}
