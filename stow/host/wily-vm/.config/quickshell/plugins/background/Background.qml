import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../../Ui" as Ui

Scope {
  id: background

  required property var shell

  function open() { picker.open() }
  function close() { picker.close() }
  function toggle() { picker.toggle() }

  readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
  property list<string> wallpapers: []
  property string darkPick: ""
  property string lightPick: ""
  readonly property string wallpaper: shell.dark ? darkPick : lightPick
  property string preview: ""
  readonly property string shownWallpaper: preview || wallpaper

  Timer {
    id: previewDelay
    interval: 250
    onTriggered: background.preview = picker.shown && grid.currentIndex >= 0
      ? (background.wallpapers[grid.currentIndex] || "") : ""
  }

  Connections {
    target: picker
    function onShownChanged() {
      if (picker.shown) {
        previewDelay.restart()
      } else {
        previewDelay.stop()
        background.preview = ""
      }
    }
  }

  function setWallpaper(path) {
    if (shell.dark) {
      darkPick = path
      darkState.setText(path + "\n")
    } else {
      lightPick = path
      lightState.setText(path + "\n")
    }
  }

  Process {
    id: scan
    running: true
    command: ["find", background.wallpaperDir, "-type", "f",
              "-iregex", ".*\\.\\(png\\|jpg\\|jpeg\\|webp\\)"]
    stdout: StdioCollector {
      onStreamFinished: background.wallpapers = text.trim().split("\n").filter(l => l.length > 0).sort()
    }
  }

  FileView {
    id: darkState
    path: Quickshell.env("HOME") + "/.local/state/wallpaper-dark"
    atomicWrites: true
    printErrors: false
    onLoaded: background.darkPick = text().trim()
  }

  FileView {
    id: lightState
    path: Quickshell.env("HOME") + "/.local/state/wallpaper-light"
    atomicWrites: true
    printErrors: false
    onLoaded: background.lightPick = text().trim()
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void { picker.toggle() }
    function open(): void { picker.open() }
    function close(): void { picker.close() }
    function rescan(): void { scan.running = true }
    function set(path: string): void { background.setWallpaper(path) }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Background
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0.0; color: background.shell.palette.dim }
          GradientStop { position: 1.0; color: background.shell.palette.bg }
        }
      }

      Item {
        id: wall
        anchors.fill: parent
        readonly property string src: background.shownWallpaper
          ? "file://" + background.shownWallpaper : ""

        function swap() {
          if (!src) {
            under.source = ""
            over.source = ""
            return
          }
          if (String(over.source) === src) return
          fade.enabled = false
          over.opacity = 0
          fade.enabled = true

          under.source = over.source
          over.source = src
          over.opacity = 1
        }

        Image {
          id: loader
          source: wall.src
          asynchronous: true
          visible: false
          onStatusChanged: if (status === Image.Ready) wall.swap()
          onSourceChanged: if (status === Image.Ready) wall.swap()
          Component.onCompleted: if (status === Image.Ready) wall.swap()
        }

        Image {
          id: under
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
        }

        Image {
          id: over
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          opacity: 0
          Behavior on opacity {
            id: fade
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
          }
        }
      }
    }
  }

  Ui.Panel {
    id: picker
    shell: background.shell
    cardWidth: 840
    cardHeight: 540

    function open() {
      scan.running = true
      if (background.shell && background.shell.registerPanel) background.shell.registerPanel(picker)
      if (background.shell && background.shell.claimPanel) background.shell.claimPanel(picker)
      shown = true
      grid.currentIndex = Math.max(0, background.wallpapers.indexOf(background.wallpaper))
      grid.forceActiveFocus()
    }

    function choose() {
      const path = background.wallpapers[grid.currentIndex]
      close()
      if (path) background.setWallpaper(path)
    }

    Text {
      color: background.shell.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 15
      text: "Wallpaper · " + (background.shell.dark ? "dark" : "light")
    }

    GridView {
      id: grid
      width: parent.width
      height: parent.height - y
      clip: true
      focus: true
      cellWidth: width / 4
      cellHeight: cellWidth * 9 / 16
      model: background.wallpapers
      onCurrentIndexChanged: previewDelay.restart()

      delegate: Item {
        required property var modelData
        required property int index

        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
          anchors.fill: parent
          anchors.margins: 4
          radius: 4
          clip: true
          color: background.shell.palette.dim
          border.color: index === grid.currentIndex ? background.shell.palette.fg : "transparent"
          border.width: 2

          Image {
            anchors.fill: parent
            anchors.margins: 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 480
            source: "file://" + modelData
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              grid.currentIndex = index
              picker.choose()
            }
          }
        }
      }

      Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) picker.close()
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) picker.choose()
        else return
        event.accepted = true
      }
    }
  }
}
