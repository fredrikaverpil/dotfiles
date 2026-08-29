import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  // Reached from Hyprland with `qs ipc call launcher toggle`. The bar button
  // calls launcher.toggle() directly — same process, no subprocess needed.
  IpcHandler {
    target: "launcher"

    function toggle(): void { launcher.toggle() }
    function open(): void { launcher.open() }
    function close(): void { launcher.close() }
  }

  PanelWindow {
    id: launcher

    property bool shown: false

    // A binding, not a one-shot: the desktop-entry scan finishes a few seconds
    // after startup, so a list built once at open() comes up empty.
    property var results: DesktopEntries.applications.values.filter(entry =>
      !entry.noDisplay && entry.name.toLowerCase().includes(input.text.toLowerCase()))
      .sort((a, b) => a.name.localeCompare(b.name))
    onResultsChanged: list.currentIndex = 0

    function open() {
      input.text = ""
      shown = true
      input.forceActiveFocus()
    }

    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    function launch() {
      const entry = results[list.currentIndex]
      close()
      // uwsm-app puts the app in its own scope under app-graphical.slice, so it
      // survives `systemctl --user restart quickshell` while iterating on QML.
      if (entry) Quickshell.execDetached(["uwsm-app", "--", entry.id + ".desktop"])
    }

    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: launcher.close()
    }

    Rectangle {
      anchors.centerIn: parent
      width: 600
      height: 420
      radius: 8
      color: "#1e1e2e"
      border.color: "#45475a"
      border.width: 1

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        TextInput {
          id: input
          width: parent.width
          clip: true
          color: "#cdd6f4"
          font.pixelSize: 18
          focus: true

          Text {
            anchors.fill: parent
            visible: input.text.length === 0
            color: "#6c7086"
            font: input.font
            text: "Search apps…"
          }

          Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) launcher.close()
            else if (event.key === Qt.Key_Down) list.incrementCurrentIndex()
            else if (event.key === Qt.Key_Up) list.decrementCurrentIndex()
            else if (event.key === Qt.Key_PageDown) list.currentIndex = Math.min(list.count - 1, list.currentIndex + 10)
            else if (event.key === Qt.Key_PageUp) list.currentIndex = Math.max(0, list.currentIndex - 10)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) launcher.launch()
            else return
            event.accepted = true
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: "#45475a"
        }

        ListView {
          id: list
          width: parent.width
          height: parent.height - y
          clip: true
          model: launcher.results

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: list.width
            height: 36
            color: index === list.currentIndex ? "#45475a" : "transparent"
            radius: 4

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              color: "#cdd6f4"
              font.pixelSize: 15
              text: modelData.name
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                list.currentIndex = index
                launcher.launch()
              }
            }
          }
        }
      }
    }
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

      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4
        width: apps.implicitWidth + 16
        height: 24
        radius: 4
        color: appsMouse.containsMouse ? "#45475a" : "transparent"

        Text {
          id: apps
          anchors.centerIn: parent
          color: "#cdd6f4"
          font.pixelSize: 14
          text: "Apps"
        }

        MouseArea {
          id: appsMouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: launcher.toggle()
        }
      }

      Text {
        anchors.centerIn: parent
        color: "#cdd6f4"
        font.pixelSize: 14
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
      }
    }
  }
}
