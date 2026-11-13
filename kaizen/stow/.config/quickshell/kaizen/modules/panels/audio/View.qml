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

    Ui.PanelHeader {
        shell: root.shell
        title: "Audio"
    }

    Ui.Section {
        shell: root.shell
        title: "Output"

        Column {
            width: parent.width
            spacing: 4

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

            DeviceRows {
                shell: root.shell
                service: root.service
                nodes: root.service.sinks
                current: root.service.sink
                onPicked: node => root.service.setDefault(node)
            }
        }
    }

    // Muting mutes every source, as the mic-mute key does.
    Ui.Section {
        shell: root.shell
        title: "Input"

        Column {
            width: parent.width
            spacing: 4

            Ui.PanelSlider {
                visible: !!root.service.source
                shell: root.shell
                value: root.service.micVolume
                valueText: Math.round(root.service.micVolume * 100) + "%"
                off: root.service.micMuted
                icon: root.service.micIcon
                iconColor: root.service.micMuted ? root.shell.palette.rose : root.shell.palette.fg
                onMoved: value => root.service.setMicVolume(value)
                onStepped: direction => root.service.setMicVolume(root.service.micVolume + 0.05 * direction)
                Keys.onReturnPressed: root.service.toggleMicMute()
                Keys.onEnterPressed: root.service.toggleMicMute()
                Keys.onSpacePressed: root.service.toggleMicMute()
            }

            DeviceRows {
                shell: root.shell
                service: root.service
                nodes: root.service.sources
                current: root.service.source
                onPicked: node => root.service.setDefaultSource(node)
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

    // A row per device, the current one chosen; "No devices" without any.
    component DeviceRows: Column {
        id: rows

        required property var shell
        required property var service
        required property var nodes
        required property var current

        signal picked(var node)

        width: parent ? parent.width : 0
        spacing: 4

        Text {
            visible: rows.nodes.length === 0
            color: rows.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "No devices"
        }

        Repeater {
            model: rows.nodes

            delegate: Ui.RadioRow {
                required property var modelData

                width: rows.width
                shell: rows.shell
                label: rows.service.label(modelData)
                value: rows.service.isUnplugged(modelData) ? "󰚦" : ""
                chosen: modelData === rows.current
                onActivated: rows.picked(modelData)
            }
        }
    }
}
