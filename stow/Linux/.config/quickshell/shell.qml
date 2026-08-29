import QtQuick
import Quickshell

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 32
      color: "#1e1e2e"

      Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        font.pixelSize: 14
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
      }
    }
  }
}
