import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../../Ui" as Ui

// Shown on the monitor about to be recorded; unmapped before capture starts.
PanelWindow {
  id: root

  required property var shell
  required property var service

  screen: Quickshell.screens.find(screen => screen.name === root.service.activeMonitor) || null
  visible: service.countdown > 0
  implicitWidth: 160
  implicitHeight: 160
  exclusiveZone: 0
  color: "transparent"
  mask: Region {}
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    radius: 16
    color: root.shell.palette.bg
    border.color: root.shell.palette.dim
    border.width: 1

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 96
      text: String(root.service.countdown)
    }
  }
}
