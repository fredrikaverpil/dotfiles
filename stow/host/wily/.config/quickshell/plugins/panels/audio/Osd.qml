import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../../Ui" as Ui

// Shown by the volume and mic-mute keys. No screen is set, so niri maps it on the focused output.
PanelWindow {
  id: root

  required property var shell
  required property var audio

  property bool mic: false

  function show(mic) {
    root.mic = mic
    visible = true
    hide.restart()
  }

  visible: false
  anchors.bottom: true
  margins.bottom: 64
  implicitWidth: 320
  implicitHeight: 48
  exclusiveZone: 0
  color: "transparent"
  mask: Region {}
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Timer {
    id: hide
    interval: 1500
    onTriggered: root.visible = false
  }

  Connections {
    target: root.audio

    function onAdjusted(mic) { if (!root.audio.shown) root.show(mic) }
  }

  Rectangle {
    anchors.fill: parent
    radius: 8
    color: root.shell.palette.bg
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      id: icon
      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 18
      text: root.mic ? (root.audio.micMuted ? "󰍭" : "󰍬") : root.audio.icon
    }

    Text {
      id: value
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.mic
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: Math.round(root.audio.volume * 100) + "%"
    }

    Rectangle {
      anchors.left: icon.right
      anchors.leftMargin: 12
      anchors.right: value.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.mic
      height: 6
      radius: 3
      color: root.shell.palette.dim

      Rectangle {
        width: parent.width * root.audio.volume
        height: parent.height
        radius: parent.radius
        color: root.audio.muted ? root.shell.palette.off : root.shell.palette.fg
      }
    }

    Text {
      anchors.left: icon.right
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      visible: root.mic
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: root.audio.micMuted ? "Microphone muted" : "Microphone on"
    }
  }
}
