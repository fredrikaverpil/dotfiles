import QtQuick
import Quickshell

import "../../../Ui" as Ui

// The visuals; the data comes from whichever compositor is up. The source is
// loaded by URL rather than by type so the unused one is never compiled --
// Quickshell.Hyprland connects on import, and there is no socket for it under
// niri.
Item {
  id: root

  property color foreground: "#B4BDC3"
  property color selection: "#3D4042"
  property real fontScale: 1

  // 1..5 always shown, as Omarchy does, plus any further workspace that
  // exists. niri numbers its workspaces per output from 1, so the same range
  // reads the same way under both.
  function workspaceIds() {
    const ids = [1, 2, 3, 4, 5]
    const live = source.item ? source.item.ids : []

    for (let i = 0; i < live.length; i++) {
      const id = live[i]
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort((left, right) => left - right)
    return ids
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(Ui.Compositor.focusWorkspace(id))
  }

  implicitWidth: workspaces.implicitWidth
  implicitHeight: workspaces.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Loader {
    id: source
    source: Ui.Compositor.niri ? "WorkspacesNiri.qml" : "WorkspacesHyprland.qml"
  }

  Row {
    id: workspaces
    spacing: 2

    Repeater {
      model: source.item ? root.workspaceIds() : []

      delegate: Rectangle {
        required property int modelData

        readonly property bool occupied: source.item.occupied(modelData)
        readonly property bool focused: source.item.focusedId === modelData

        width: 20
        height: 24
        radius: 4
        color: mouse.containsMouse ? root.selection : "transparent"
        opacity: occupied || focused ? 1 : 0.5
        border.width: focused ? 1 : 0
        border.color: root.foreground

        Text {
          anchors.centerIn: parent
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14 * root.fontScale
          text: modelData === 10 ? "0" : String(modelData)
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          onClicked: root.focusWorkspace(modelData)
        }
      }
    }
  }
}
