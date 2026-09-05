import QtQuick
import Quickshell

import "widgets" as BarWidgets
import "../../Ui" as Ui

// The top bar, one per screen.
Scope {
  id: bar

  required property var shell

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

      Ui.BarButton {
        id: menuButton
        shell: bar.shell
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

      // Opens the launcher at its system level rather than owning a panel:
      // that level already holds lock, idle, suspend, logout, reboot and
      // shutdown, and SUPER + ESCAPE already goes there.
      Ui.BarButton {
        id: powerButton
        shell: bar.shell
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: "󰐥"
        onActivated: bar.shell.menu.toggleLevel("system")
      }

      Ui.BarButton {
        id: notificationButton
        shell: bar.shell
        anchors.right: powerButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.notifications.doNotDisturb ? "󰂛" : "󰂚"
        onActivated: bar.shell.notifications.toggleHistory()
      }

      Ui.BarButton {
        id: displayButton
        shell: bar.shell
        anchors.right: notificationButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: "󰍹"
        onActivated: bar.shell.display.toggle()
      }

      Ui.BarButton {
        id: networkButton
        shell: bar.shell
        anchors.right: displayButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.networkService.icon
        onActivated: bar.shell.network.toggle()
      }

      Ui.BarButton {
        id: audioButton
        shell: bar.shell
        anchors.right: networkButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.audio.icon
        onActivated: bar.shell.audio.toggle()
      }

      // Indicators grow inward from here, so the buttons above keep their
      // places at the right edge when one appears. Clicking restores the
      // default, which is the only thing anyone wants from a coffee cup.
      Ui.BarButton {
        id: idleButton
        shell: bar.shell
        anchors.right: audioButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 4 : 0
        visible: !bar.shell.idle.enabled
        label: "󰅶"
        onActivated: bar.shell.idle.setEnabled(true)
      }

      BarWidgets.Tray {
        anchors.right: idleButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        shell: bar.shell
        panel: bar.shell.tray
      }
    }
  }
}
