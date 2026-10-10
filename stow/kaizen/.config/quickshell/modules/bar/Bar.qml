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

    // The plugin that took over the date button, if any.
    readonly property var datePlugin: bar.shell.plugins.filter(plugin => plugin.barActions.date).pop()

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
                onSecondary: bar.shell.menu.popup("root", modelData.name, menuButton)
            }

            BarWidgets.Workspaces {
                id: workspaces
                anchors.left: menuButton.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                output: modelData.name
                foreground: bar.shell.palette.fg
                selection: bar.shell.palette.sel
                fontScale: bar.shell.textScale
            }

            // Centered until a side group reaches it, then pushed aside.
            Row {
                id: clockGroup
                x: Math.max(workspaces.x + workspaces.width + 12, Math.min((parent.width - width) / 2, tray.x - width - 12))
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Ui.BarButton {
                    id: weatherButton
                    shell: bar.shell
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 58 * bar.shell.textScale
                    label: bar.shell.weatherService.ready ? bar.shell.weatherService.icon + " " + bar.shell.weatherService.temperature : bar.shell.weatherService.icon
                    onActivated: bar.shell.weather.toggle()
                    onSecondary: bar.shell.menu.popup("settings.weather", modelData.name, weatherButton)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 16 * bar.shell.textScale
                    color: bar.shell.palette.dim
                }

                // A plain label unless a plugin takes it over.
                Ui.BarButton {
                    id: dateLabel
                    shell: bar.shell
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: bar.datePlugin !== undefined
                    label: Qt.formatDateTime(clock.date, "ddd d MMM")
                    onActivated: bar.datePlugin.barActions.date()
                    onSecondary: bar.shell.menu.popup("plugins." + bar.datePlugin.name, modelData.name, dateLabel)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 16 * bar.shell.textScale
                    color: bar.shell.palette.dim
                }

                Ui.BarButton {
                    id: timeLabel
                    shell: bar.shell
                    anchors.verticalCenter: parent.verticalCenter
                    label: Qt.formatDateTime(clock.date, "HH:mm")
                    onActivated: bar.shell.timezone.toggle()
                    onSecondary: bar.shell.menu.popup("settings.clock", modelData.name, timeLabel)
                    onLabelChanged: if (label.endsWith(":00"))
                        hourPulse.restart()

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

            Ui.BarButton {
                id: notificationButton
                shell: bar.shell
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                readonly property int pending: bar.shell.notifications.historyRows.length
                property bool dimmed: false
                foreground: bar.shell.notifications.doNotDisturb ? bar.shell.palette.rose : bar.shell.palette.fg
                label: (bar.shell.notifications.doNotDisturb ? "󰂛" : "󰂚") + (notificationButton.pending > 0 ? " " + notificationButton.pending : "")
                onActivated: bar.shell.notifications.toggleHistory()
                onSecondary: bar.shell.menu.popup("settings.notifications", modelData.name, notificationButton)

                // Blinks while DnD is overdue, faster while it holds back a critical one.
                opacity: blinker.running && dimmed ? 0.2 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
                Timer {
                    id: blinker
                    running: bar.shell.notifications.dndOverdue || bar.shell.notifications.criticalHeld
                    interval: bar.shell.notifications.criticalHeld ? 250 : 800
                    repeat: true
                    onTriggered: notificationButton.dimmed = !notificationButton.dimmed
                }
            }

            // Separates settings from notifications.
            Rectangle {
                id: notificationDivider
                anchors.right: notificationButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                width: 1
                height: 16 * bar.shell.textScale
                color: bar.shell.palette.dim
            }

            Ui.BarButton {
                id: batteryButton
                shell: bar.shell
                anchors.right: notificationDivider.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 6 : 0
                visible: bar.shell.batteryService.present
                implicitWidth: visible ? 64 * bar.shell.textScale : 0
                foreground: !bar.shell.batteryService.onBattery ? bar.shell.palette.fg : bar.shell.batteryService.percentage <= bar.shell.batteryService.lowLevel ? bar.shell.palette.rose : bar.shell.batteryService.percentage <= bar.shell.batteryService.warnLevel ? bar.shell.palette.wood : bar.shell.palette.fg
                label: bar.shell.batteryService.icon + " " + bar.shell.batteryService.percentage + "%"
                onActivated: bar.shell.battery.toggle()
                onSecondary: bar.shell.menu.popup("settings.power", modelData.name, batteryButton)
            }

            Ui.BarButton {
                id: networkButton
                shell: bar.shell
                anchors.right: batteryButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: batteryButton.visible ? 4 : 6
                readonly property string ssid: bar.shell.networkService.kind === "wifi" && bar.shell.networkService.connectedWifiNetwork ? bar.shell.networkService.connectedWifiNetwork.name : ""
                foreground: bar.shell.networkService.kind === "disconnected" ? bar.shell.palette.rose : bar.shell.palette.fg
                // At most 16 characters; the panel shows the full name.
                label: bar.shell.networkService.icon + (ssid ? " " + (ssid.length > 16 ? ssid.slice(0, 15) + "…" : ssid) : "")
                onActivated: bar.shell.network.toggle()
                onSecondary: bar.shell.menu.popup("settings.network", modelData.name, networkButton)
            }

            Ui.BarButton {
                id: bluetoothButton
                shell: bar.shell
                anchors.right: networkButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                foreground: !bar.shell.bluetoothService.powered || bar.shell.bluetoothService.lowestBattery >= 0 && bar.shell.bluetoothService.lowestBattery <= bar.shell.batteryService.lowLevel ? bar.shell.palette.rose : bar.shell.bluetoothService.lowestBattery >= 0 && bar.shell.bluetoothService.lowestBattery <= bar.shell.batteryService.warnLevel ? bar.shell.palette.wood : bar.shell.palette.fg
                label: bar.shell.bluetoothService.icon
                onActivated: bar.shell.bluetooth.toggle()
                onSecondary: bar.shell.menu.popup("settings.bluetooth", modelData.name, bluetoothButton)
            }

            Ui.BarButton {
                id: displayButton
                shell: bar.shell
                anchors.right: bluetoothButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                label: "󰍹"
                onActivated: bar.shell.display.toggle()
                onSecondary: bar.shell.menu.popup("settings.display", modelData.name, displayButton)
            }

            Ui.BarButton {
                id: audioButton
                shell: bar.shell
                anchors.right: displayButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                foreground: bar.shell.audio.muted ? bar.shell.palette.rose : bar.shell.palette.fg
                label: bar.shell.audio.icon
                onActivated: bar.shell.audio.toggle()
                onSecondary: bar.shell.menu.popup("settings.audio", modelData.name, audioButton)
            }

            // Separates status indicators from the settings.
            Rectangle {
                id: indicatorDivider
                anchors.right: audioButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 6 : 0
                visible: idleButton.visible || keyboardButton.visible || recordingButton.visible || mirrorButton.visible || systemButton.visible || firmwareButton.visible || logButton.visible || mediaWidget.width > 0 || pluginIndicators.width > 0
                width: visible ? 1 : 0
                height: 16 * bar.shell.textScale
                color: bar.shell.palette.dim
            }

            Media.BarWidget {
                id: mediaWidget
                anchors.right: indicatorDivider.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: width > 0 ? 6 : 0
                shell: bar.shell
                output: modelData.name
            }

            Ui.BarButton {
                id: idleButton
                shell: bar.shell
                anchors.right: mediaWidget.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? (mediaWidget.width > 0 ? 4 : 6) : 0
                visible: !bar.shell.idle.enabled
                foreground: bar.shell.palette.rose
                label: "󱙱"
                onActivated: bar.shell.idle.setEnabled(true)
            }

            Ui.BarButton {
                id: keyboardButton
                shell: bar.shell
                anchors.right: idleButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 4 : 0
                visible: !bar.shell.keyboard.isDefault
                label: bar.shell.keyboard.name
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
                implicitWidth: visible ? 76 * bar.shell.textScale : 0
                foreground: bar.shell.recordingService.paused ? bar.shell.palette.off : bar.shell.palette.rose
                label: "󰑊 " + (bar.shell.recordingService.countdown > 0 ? bar.shell.recordingService.countdown : RecordingModel.elapsed(bar.shell.recordingService.seconds))
                onActivated: bar.shell.recordingService.stop()
                onSecondary: bar.shell.recordingService.togglePause()
            }

            Ui.BarButton {
                id: mirrorButton
                shell: bar.shell
                anchors.right: recordingButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 4 : 0
                visible: bar.shell.mirror.active
                enabled: !bar.shell.mirror.busy
                foreground: bar.shell.palette.rose
                label: "󰍺"
                onActivated: bar.shell.mirror.stopAll()
            }

            Ui.BarButton {
                id: systemButton
                shell: bar.shell
                anchors.right: mirrorButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 4 : 0
                visible: bar.shell.systemService.alert !== null
                // A plain label.
                enabled: false
                foreground: bar.shell.palette.rose
                label: bar.shell.systemService.alertLabel
            }

            // Pending firmware updates.
            Ui.BarButton {
                id: firmwareButton
                shell: bar.shell
                anchors.right: systemButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 4 : 0
                visible: bar.shell.firmwareService.updates.length > 0
                // Wood even when urgent: updates can wait for a convenient reboot.
                foreground: bar.shell.palette.wood
                label: "󰚰"
                onActivated: bar.shell.firmware.open()
                onSecondary: bar.shell.menu.popup("settings.firmware", modelData.name, firmwareButton)
            }

            // kaizen-log is not silent.
            Ui.BarButton {
                id: logButton
                shell: bar.shell
                anchors.right: firmwareButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 4 : 0
                visible: bar.shell.logService.count > 0
                foreground: bar.shell.logService.errors > 0 ? bar.shell.palette.rose : bar.shell.palette.wood
                label: "󰃤"
                onActivated: bar.shell.log.open()
                onSecondary: bar.shell.menu.popup("settings.log", modelData.name, logButton)
            }

            // In plugin load order; right-click opens the plugin's node.
            Row {
                id: pluginIndicators
                anchors.right: logButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: width > 0 ? 4 : 0
                spacing: 4

                Repeater {
                    model: bar.shell.plugins

                    Ui.BarButton {
                        id: pluginIndicator
                        required property var modelData
                        shell: bar.shell
                        visible: modelData.barIndicator !== null
                        foreground: modelData.barIndicator && modelData.barIndicator.foreground || bar.shell.palette.fg
                        label: modelData.barIndicator ? modelData.barIndicator.label : ""
                        onActivated: modelData.barIndicator.action()
                        onSecondary: bar.shell.menu.popup("plugins." + modelData.name, barWindow.modelData.name, pluginIndicator)
                    }
                }
            }

            // Separates app tray icons from the indicators and system buttons.
            Rectangle {
                id: trayDivider
                anchors.right: pluginIndicators.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: visible ? 6 : 0
                visible: tray.width > 0
                width: visible ? 1 : 0
                height: 16 * bar.shell.textScale
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
                // Between the centered clock group, with its 12px gap, and the indicators, less
                // the tray divider and its margins.
                maxWidth: pluginIndicators.x - 13 - (parent.width + clockGroup.width) / 2 - 12
            }
        }
    }
}
