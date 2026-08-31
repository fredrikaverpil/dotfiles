import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../../Ui" as Ui

// The wallpaper: the surface behind every window, and the picker that chooses
// it.
Scope {
  id: background

  required property var shell

  function open() { picker.open() }
  function close() { picker.close() }
  function toggle() { picker.toggle() }

  // Wallpaper. Images live in ~/Pictures/wallpapers — outside this repo, so
  // nothing binary gets committed — and the pick is per mode, persisted as a
  // path in ~/.local/state/wallpaper-{dark,light}. The gradient below shows
  // through until a mode has been given a picture.
  readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
  property list<string> wallpapers: []
  property string darkPick: ""
  property string lightPick: ""
  readonly property string wallpaper: shell.dark ? darkPick : lightPick

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

      Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: background.wallpaper ? "file://" + background.wallpaper : ""
      }
    }
  }

  // The picker. Escape and Enter are on the grid rather than the panel,
  // since the grid is what holds focus while it is open.
  Ui.Panel {
    id: picker
    shell: background.shell
    cardWidth: 840
    cardHeight: 540

    function open() {
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
      // The pick applies to the mode that is on now, so name it.
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
            // Thumbnails, not full decodes: the source images run to megabytes.
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
