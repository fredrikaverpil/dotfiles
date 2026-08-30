import QtQuick
import Quickshell

import "widgets" as BarWidgets

// The top bar, one per screen.
Scope {
  id: bar

  required property var shell

  // Bar chrome, so every button hovers and reads the same. Keep an icon slot
  // independent of its glyph: the light and dark symbols have different font
  // advances, and a content-sized slot makes its neighbour jump on a toggle.
  component BarButton: Rectangle {
    id: btn

    property alias label: btnLabel.text
    property string fontFamily: "JetBrainsMono Nerd Font"
    signal activated

    implicitWidth: 28
    width: implicitWidth
    height: 24
    radius: 4
    color: btnMouse.containsMouse ? bar.shell.palette.sel : "transparent"

    TextMetrics {
      id: btnMetrics
      font.family: btnLabel.font.family
      font.pixelSize: btnLabel.font.pixelSize
      text: btnLabel.text
    }

    Text {
      id: btnLabel
      anchors.centerIn: parent
      // Text centers its advance box, not the pixels it paints. Correct that
      // horizontal difference so differently shaped Nerd Font glyphs share a
      // visual centre in the fixed slot.
      anchors.horizontalCenterOffset: implicitWidth / 2
        - (btnMetrics.tightBoundingRect.x + btnMetrics.tightBoundingRect.width / 2)
      color: bar.shell.palette.fg
      font.family: btn.fontFamily
      font.pixelSize: 14 * bar.shell.textScale
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: btn.activated()
    }
  }

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
      implicitHeight: bar.shell.barHeight
      color: bar.shell.palette.bg

      BarButton {
        id: menuButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4
        // U+E900 in the vendored Omarchy icon font; see wily-vm/CLAUDE.md.
        label: "\ue900"
        fontFamily: "omarchy"
        onActivated: bar.shell.menu.toggle()
      }

      BarWidgets.Workspaces {
        anchors.left: menuButton.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        foreground: bar.shell.palette.fg
        selection: bar.shell.palette.sel
        fontScale: bar.shell.textScale
      }

      Text {
        anchors.centerIn: parent
        color: bar.shell.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14 * bar.shell.textScale
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
      }

      BarButton {
        id: notificationButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.notifications.doNotDisturb ? "󰂛" : "󰂚"
        onActivated: bar.shell.notifications.toggleHistory()
      }

      BarButton {
        id: displayButton
        anchors.right: notificationButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: "󰍹"
        onActivated: bar.shell.display.toggle()
      }

      BarButton {
        anchors.right: displayButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.network.icon
        onActivated: bar.shell.network.toggle()
      }
    }
  }
}
