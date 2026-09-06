import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/media/MediaModel.js" as Model

// Title, art, controls and sources, all reachable through Ui.Panel's focus
// chain. The bar button and the launcher both land here.
Ui.Panel {
  id: root

  required property var service

  // shell.media names this panel, so proxy the service state the bar reads.
  readonly property bool hasMedia: service.hasMedia
  readonly property string icon: service.icon
  readonly property var players: service.sourcePlayers
  readonly property bool multipleSources: players.length > 1

  cardWidth: 480
  cardHeight: multipleSources ? 280 + players.length * 34 : 244
  keyNavigation: true

  IpcHandler {
    target: "media"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.service.statusJson() }
    function playPause(): string { return root.service.runAction("playPause") ? "ok" : "unhandled" }
    function previous(): string { return root.service.runAction("previous") ? "ok" : "unhandled" }
    function next(): string { return root.service.runAction("next") ? "ok" : "unhandled" }
    function play(): string { return root.service.runAction("play") ? "ok" : "unhandled" }
    function pause(): string { return root.service.runAction("pause") ? "ok" : "unhandled" }
    function select(key: string): string { return root.service.selectPlayer(key) ? "ok" : "unknown" }
  }

  Text {
    width: parent.width
    color: root.shell.palette.fg
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 18
    text: "Media"
  }

  Text {
    width: parent.width
    color: root.shell.palette.off
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    text: root.service.identity || "No MPRIS player"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Row {
    width: parent.width
    height: 94
    spacing: 12

    Rectangle {
      width: 94
      height: 94
      radius: 4
      color: root.shell.palette.sel
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

      Text {
        anchors.centerIn: parent
        visible: art.status !== Image.Ready
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 30
        text: "󰝚"
      }
    }

    Column {
      width: parent.width - 106
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Text {
        width: parent.width
        elide: Text.ElideRight
        color: root.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        font.bold: true
        text: root.service.title || "Nothing playing"
      }

      Text {
        width: parent.width
        elide: Text.ElideRight
        visible: text.length > 0
        color: root.shell.palette.off
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        text: root.service.artist
      }

      Text {
        width: parent.width
        elide: Text.ElideRight
        visible: text.length > 0
        color: root.shell.palette.off
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        text: root.service.album
      }
    }
  }

  Row {
    width: parent.width
    spacing: 6

    ControlButton {
      width: (parent.width - parent.spacing * 2) / 3
      label: "󰒮"
      available: root.service.activePlayer && root.service.activePlayer.canGoPrevious
      onActivated: root.service.runAction("previous")
    }

    ControlButton {
      width: (parent.width - parent.spacing * 2) / 3
      label: root.service.playing ? "󰏤" : "󰐊"
      available: root.service.activePlayer && (root.service.activePlayer.canTogglePlaying
        || root.service.activePlayer.canPlay || root.service.activePlayer.canPause)
      onActivated: root.service.runAction("playPause")
    }

    ControlButton {
      width: (parent.width - parent.spacing * 2) / 3
      label: "󰒭"
      available: root.service.activePlayer && root.service.activePlayer.canGoNext
      onActivated: root.service.runAction("next")
    }
  }

  Text {
    width: parent.width
    visible: root.multipleSources
    color: root.shell.palette.off
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    text: "Sources"
  }

  Repeater {
    model: root.players

    delegate: SourceButton {
      required property var modelData

      width: parent.width
      visible: root.multipleSources
      selected: root.service.playerKey(modelData) === root.service.playerKey(root.service.activePlayer)
      label: Model.labelFor(modelData)
      detail: Model.detailFor(modelData)
      playing: !!modelData.isPlaying
      onActivated: root.service.selectPlayer(root.service.playerKey(modelData))
    }
  }

  // Keyed on visibility, never availability: an MPRIS player can change a
  // capability while a button has focus, and dropping it from the chain then
  // would strand the cursor.
  component ControlButton: Rectangle {
    property string label: ""
    property bool available: true
    signal activated

    height: 30
    radius: 4
    color: activeFocus ? root.shell.palette.sel : "transparent"
    border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    opacity: available ? 1 : 0.45
    activeFocusOnTab: true

    Keys.onReturnPressed: if (available) activated()
    Keys.onEnterPressed: if (available) activated()
    Keys.onSpacePressed: if (available) activated()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 16
      text: parent.label
    }

    MouseArea {
      anchors.fill: parent
      enabled: parent.available
      onClicked: parent.activated()
    }
  }

  component SourceButton: Rectangle {
    property string label: ""
    property string detail: ""
    property bool selected: false
    property bool playing: false
    signal activated

    height: 28
    radius: 4
    color: activeFocus || selected ? root.shell.palette.sel : "transparent"
    border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    activeFocusOnTab: true

    Keys.onReturnPressed: activated()
    Keys.onEnterPressed: activated()
    Keys.onSpacePressed: activated()

    Text {
      id: sourceIcon
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
      text: parent.playing ? "󰏤" : "󰐊"
    }

    Text {
      anchors.left: sourceIcon.right
      anchors.leftMargin: 8
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      color: root.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 13
      font.bold: parent.selected
      text: parent.label + (parent.detail && parent.detail !== parent.label
        ? " · " + parent.detail : "")
    }

    MouseArea {
      anchors.fill: parent
      onClicked: parent.activated()
    }
  }
}
