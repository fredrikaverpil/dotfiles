import QtQuick

import "../../../Ui" as Ui
import "../../services/media/MediaModel.js" as Model

Column {
    id: root

    required property var shell
    required property var service

    readonly property var players: service.sourcePlayers
    readonly property bool multipleSources: players.length > 1
    readonly property var player: service.activePlayer
    // No player: the header alone, its subtitle says so.
    readonly property bool hasPlayer: !!player
    // Seconds h/l seek by.
    readonly property int seekStep: 5

    readonly property int cardWidth: 400
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 24

    Column {
        width: parent.width
        spacing: 16

        // Several players: the Sources group names the chosen one instead.
        Ui.PanelHeader {
            shell: root.shell
            title: "Media"
            subtitle: root.multipleSources ? "" : root.service.identity || "No MPRIS player"
        }

        Row {
            visible: root.hasPlayer
            width: parent.width
            height: 94
            spacing: 16

            Rectangle {
                width: 94
                height: 94
                radius: 4
                color: "transparent"
                border.color: root.shell.palette.dim
                border.width: 1

                Image {
                    id: art
                    anchors.fill: parent
                    anchors.margins: 1
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    source: root.service.artUrl
                }

                // Off the type scale (style.md › Panels › Type): it stands in for the art, not text.
                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 30
                    text: "󰝚"
                }
            }

            Column {
                width: parent.width - 94 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: root.service.title ? root.shell.palette.fg : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: root.service.title || "Nothing playing"
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text.length > 0
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: root.service.artist
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text.length > 0
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: root.service.album
                }
            }
        }

        // A meter where the player cannot seek; none for a live stream.
        Ui.PanelSlider {
            visible: root.service.hasLength
            shell: root.shell
            interactive: root.service.canSeek
            value: root.service.length > 0 ? root.service.position / root.service.length : 0
            valueText: Model.formatPosition(root.service.position)
            valueWidest: Model.formatPosition(root.service.length)
            onMoved: value => root.service.seek(value * root.service.length)
            onStepped: direction => root.service.seek(root.service.position + direction * root.seekStep)
        }

        Row {
            visible: root.hasPlayer
            width: parent.width
            spacing: 8

            Ui.PanelButton {
                width: (parent.width - parent.spacing * 2) / 3
                shell: root.shell
                label: "󰒮"
                available: Model.canHandleAction(root.player, "previous")
                onActivated: root.service.runAction("previous")
            }

            Ui.PanelButton {
                width: (parent.width - parent.spacing * 2) / 3
                shell: root.shell
                label: root.service.playing ? "󰏤" : "󰐊"
                available: Model.canHandleAction(root.player, "playPause")
                onActivated: root.service.runAction("playPause")
            }

            Ui.PanelButton {
                width: (parent.width - parent.spacing * 2) / 3
                shell: root.shell
                label: "󰒭"
                available: Model.canHandleAction(root.player, "next")
                onActivated: root.service.runAction("next")
            }
        }
    }

    Ui.Section {
        visible: root.multipleSources
        shell: root.shell
        title: "Sources"

        Repeater {
            model: root.players

            delegate: Ui.RadioRow {
                required property var modelData
                readonly property string detail: Model.detailFor(modelData)

                width: root.width
                shell: root.shell
                label: Model.labelFor(modelData) + (detail && detail !== Model.labelFor(modelData) ? " · " + detail : "")
                chosen: root.service.playerKey(modelData) === root.service.playerKey(root.player)
                value: modelData.isPlaying ? "󰏤" : "󰐊"
                valueColor: modelData.isPlaying ? root.shell.palette.fg : root.shell.palette.off
                onActivated: root.service.selectPlayer(root.service.playerKey(modelData))
            }
        }
    }
}
