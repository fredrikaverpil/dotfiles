import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  // Light/dark. The dconf key is the source of truth, not a property of ours:
  // xdg-desktop-portal-gtk republishes it as org.freedesktop.appearance, which
  // is what flips Ghostty's theme live, and Neovim follows the terminal over
  // OSC 11. gtk-theme comes along so GTK apps switch too.
  property bool dark: true
  readonly property var palette: dark
    ? ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833" })
    : ({ bg: "#F0EDEC", fg: "#2C363C", sel: "#CBD9E3", dim: "#CFC1BA" })

  function setDark(on) {
    const scheme = on ? "prefer-dark" : "prefer-light"
    const gtk = on ? "Adwaita-dark" : "Adwaita"
    write.command = ["sh", "-c",
      "dconf write /org/gnome/desktop/interface/color-scheme \"'" + scheme + "'\"; " +
      "dconf write /org/gnome/desktop/interface/gtk-theme \"'" + gtk + "'\""]
    write.running = true
  }

  Process { id: write }

  IpcHandler {
    target: "theme"

    function toggle(): void { root.setDark(!root.dark) }
    function dark(): void { root.setDark(true) }
    function light(): void { root.setDark(false) }
  }

  // Watched, not just written, so a `dconf write` from a shell moves the bar
  // too. dconf watch prints the key on one line and the value on the next.
  Process {
    running: true
    command: ["dconf", "watch", "/org/gnome/desktop/interface/"]
    stdout: SplitParser {
      onRead: line => {
        if (line.indexOf("prefer-dark") >= 0) root.dark = true
        else if (line.indexOf("prefer-light") >= 0) root.dark = false
      }
    }
  }

  Process {
    running: true
    command: ["dconf", "read", "/org/gnome/desktop/interface/color-scheme"]
    stdout: StdioCollector {
      onStreamFinished: root.dark = text.indexOf("prefer-light") < 0
    }
  }

  // Bar chrome, so every button hovers and reads the same.
  component BarButton: Rectangle {
    id: btn

    property alias label: btnLabel.text
    signal activated

    implicitWidth: btnLabel.implicitWidth + 16
    width: implicitWidth
    height: 24
    radius: 4
    color: btnMouse.containsMouse ? root.palette.sel : "transparent"

    Text {
      id: btnLabel
      anchors.centerIn: parent
      color: root.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
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
      color: root.palette.bg
      border.color: root.palette.dim
      border.width: 1

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        TextInput {
          id: input
          width: parent.width
          clip: true
          color: root.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
          focus: true

          Text {
            anchors.fill: parent
            visible: input.text.length === 0
            color: root.palette.dim
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
          color: root.palette.dim
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
            color: index === list.currentIndex ? root.palette.sel : "transparent"
            radius: 4

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              color: root.palette.fg
              font.family: "JetBrainsMono Nerd Font"
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
      color: root.palette.bg

      Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4
        spacing: 4

        Repeater {
          model: [
            { label: "Apps", action: () => launcher.toggle() },
          ]

          BarButton {
            required property var modelData

            label: modelData.label
            onActivated: modelData.action()
          }
        }
      }

      Text {
        anchors.centerIn: parent
        color: root.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
      }

      BarButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: root.dark ? "\uf186" : "\uf522"
        onActivated: root.setDark(!root.dark)
      }
    }
  }
}
