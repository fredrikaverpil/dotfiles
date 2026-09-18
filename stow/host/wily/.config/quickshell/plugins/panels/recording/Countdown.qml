import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../services/recording/RecordingModel.js" as Model
import "../../../Ui" as Ui

// Centred on the monitor or region about to be recorded; unmapped before capture starts.
PanelWindow {
  id: root

  required property var shell
  required property var service

  readonly property var region: service.shownRegion
  readonly property var regionScreen: region ? Model.screenAt(service.screens, region) : null
  readonly property string screenName: regionScreen ? regionScreen.name : service.activeMonitor

  screen: Quickshell.screens.find(screen => screen.name === root.screenName) || null
  visible: service.countdown > 0
  anchors.left: regionScreen !== null
  anchors.top: regionScreen !== null
  margins.left: regionScreen ? Math.max(0, region.x - regionScreen.x + (region.width - implicitWidth) / 2) : 0
  margins.top: regionScreen ? Math.max(0, region.y - regionScreen.y + (region.height - implicitHeight) / 2) : 0
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
