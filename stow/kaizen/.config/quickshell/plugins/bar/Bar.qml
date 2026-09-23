import QtQuick
import Quickshell
import Quickshell.Wayland

import "widgets" as BarWidgets
import "../services/media" as Media
import "../services/recording/RecordingModel.js" as RecordingModel
import "../../Ui" as Ui

Scope {
  id: bar

  required property var shell

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData

      // Idle locking would interrupt a long recording.
      IdleInhibitor {
        window: barWindow
        enabled: bar.shell.recordingService.recording
      }

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
        label: "❄"
        onActivated: bar.shell.menu.toggle()
      }

      BarWidgets.Workspaces {
        anchors.left: menuButton.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        output: modelData.name
        foreground: bar.shell.palette.fg
        selection: bar.shell.palette.sel
        fontScale: bar.shell.textScale
      }

      Row {
        id: clockLabel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        spacing: 6

        Ui.BarButton {
          shell: bar.shell
          anchors.verticalCenter: parent.verticalCenter
          label: Qt.formatDateTime(clock.date, "ddd d MMM")
          onActivated: bar.shell.calendar.toggle()
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: 16
          color: bar.shell.palette.dim
        }

        Ui.BarButton {
          id: timeLabel
          shell: bar.shell
          anchors.verticalCenter: parent.verticalCenter
          fontSize: 14 * bar.shell.textScale
          label: Qt.formatDateTime(clock.date, "HH:mm")
          onActivated: bar.shell.timezone.toggle()
          onLabelChanged: if (label.endsWith(":00")) hourPulse.restart()

          SequentialAnimation {
            id: hourPulse
            loops: 3
            NumberAnimation {
              target: timeLabel
              property: "scale"
              to: 1.25
              duration: 200
              easing.type: Easing.OutQuad
            }
            NumberAnimation {
              target: timeLabel
              property: "scale"
              to: 1.0
              duration: 200
              easing.type: Easing.InQuad
            }
          }
        }
      }

      Rectangle {
        id: weatherDivider
        anchors.right: clockLabel.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 6
        width: 1
        height: 16
        color: bar.shell.palette.dim
      }

      Ui.BarButton {
        id: weatherButton
        shell: bar.shell
        anchors.right: weatherDivider.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 58
        label: bar.shell.weatherService.ready
          ? bar.shell.weatherService.icon + " " + bar.shell.weatherService.temperature
          : bar.shell.weatherService.icon
        onActivated: bar.shell.weather.toggle()
        onSecondary: bar.shell.weatherService.refresh()
      }

      // Separates the clock and weather from the session buttons.
      Rectangle {
        id: clockDivider
        anchors.right: weatherButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 6
        width: 1
        height: 16
        color: bar.shell.palette.dim
      }

      Ui.BarButton {
        id: powerButton
        shell: bar.shell
        anchors.right: clockDivider.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 6
        label: "󰐥"
        onActivated: bar.shell.menu.toggleLevel("system")
      }

      Ui.BarButton {
        id: notificationButton
        shell: bar.shell
        anchors.right: powerButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        readonly property int pending: bar.shell.notifications.historyRows.length
        label: (bar.shell.notifications.doNotDisturb ? "󰂛" : "󰂚")
          + (notificationButton.pending > 0 ? " " + notificationButton.pending : "")
        onActivated: bar.shell.notifications.toggleHistory()
      }

      Ui.BarButton {
        id: clipboardButton
        shell: bar.shell
        anchors.right: notificationButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: "\u{F014C}"
        onActivated: bar.shell.clipboard.toggle()
      }

      // Separates settings from the session buttons.
      Rectangle {
        id: sessionDivider
        anchors.right: clipboardButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 6
        width: 1
        height: 16
        color: bar.shell.palette.dim
      }

      Ui.BarButton {
        id: batteryButton
        shell: bar.shell
        anchors.right: sessionDivider.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 6 : 0
        visible: bar.shell.batteryService.present
        implicitWidth: visible ? 64 : 0
        label: bar.shell.batteryService.icon + " " + bar.shell.batteryService.percentage + "%"
        onActivated: bar.shell.battery.toggle()
      }

      Ui.BarButton {
        id: networkButton
        shell: bar.shell
        anchors.right: batteryButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: batteryButton.visible ? 4 : 6
        label: bar.shell.networkService.icon
          + (bar.shell.networkService.kind === "wifi"
            ? " " + bar.shell.networkService.connectedWifiNetwork.name
            : "")
        onActivated: bar.shell.network.toggle()
      }

      Ui.BarButton {
        id: bluetoothButton
        shell: bar.shell
        anchors.right: networkButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.bluetoothService.icon
        onActivated: bar.shell.bluetooth.toggle()
      }

      Ui.BarButton {
        id: displayButton
        shell: bar.shell
        anchors.right: bluetoothButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: "󰍹"
        onActivated: bar.shell.display.toggle()
      }

      Ui.BarButton {
        id: audioButton
        shell: bar.shell
        anchors.right: displayButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: bar.shell.audio.icon
        onActivated: bar.shell.audio.toggle()
      }

      // Separates status indicators from the settings.
      Rectangle {
        id: indicatorDivider
        anchors.right: audioButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 6 : 0
        visible: idleButton.visible || keyboardButton.visible || recordingButton.visible || systemButton.visible
          || mediaWidget.width > 0
        width: visible ? 1 : 0
        height: 16
        color: bar.shell.palette.dim
      }

      Media.BarWidget {
        id: mediaWidget
        anchors.right: indicatorDivider.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: width > 0 ? 6 : 0
        shell: bar.shell
      }

      Ui.BarButton {
        id: idleButton
        shell: bar.shell
        anchors.right: mediaWidget.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? (mediaWidget.width > 0 ? 4 : 6) : 0
        visible: !bar.shell.idle.enabled
        label: "󰅶"
        onActivated: bar.shell.idle.setEnabled(true)
      }

      Ui.BarButton {
        id: keyboardButton
        shell: bar.shell
        anchors.right: idleButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 4 : 0
        visible: !bar.shell.keyboard.isDefault
        label: bar.shell.keyboard.code
        fontSize: 11
        onActivated: bar.shell.keyboard.set(0)
      }

      Ui.BarButton {
        id: recordingButton
        shell: bar.shell
        anchors.right: keyboardButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 4 : 0
        visible: bar.shell.recordingService.busy
        implicitWidth: visible ? 76 : 0
        foreground: bar.shell.recordingService.paused ? bar.shell.palette.off : "#D9534F"
        label: "󰑊 " + (bar.shell.recordingService.countdown > 0
          ? bar.shell.recordingService.countdown
          : RecordingModel.elapsed(bar.shell.recordingService.seconds))
        onActivated: bar.shell.recordingService.stop()
        onSecondary: bar.shell.recordingService.togglePause()
      }

      Ui.BarButton {
        id: systemButton
        shell: bar.shell
        anchors.right: recordingButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 4 : 0
        visible: bar.shell.systemService.alert !== null
        label: bar.shell.systemService.alert ? bar.shell.systemService.alert.icon : ""
        onActivated: bar.shell.systemService.openMonitor()
      }

      // Separates app tray icons from the indicators and system buttons.
      Rectangle {
        id: trayDivider
        anchors.right: systemButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: visible ? 6 : 0
        visible: tray.width > 0
        width: visible ? 1 : 0
        height: 16
        color: bar.shell.palette.dim
      }

      BarWidgets.Tray {
        id: tray
        anchors.right: trayDivider.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: trayDivider.visible ? 6 : 0
        shell: bar.shell
        panel: bar.shell.tray
        output: modelData.name
      }
    }
  }
}
