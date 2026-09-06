import QtQuick
import Quickshell

import "../../../Ui" as Ui
import "WorkspaceModel.js" as Model

Item {
  id: root

  property color foreground: "#B4BDC3"
  property color selection: "#3D4042"
  property real fontScale: 1

  function workspaceIds() {
    return Model.workspaceIds(source.item ? source.item.ids : [])
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(Ui.Compositor.focusWorkspace(id))
  }

  implicitWidth: workspaces.implicitWidth
  implicitHeight: workspaces.implicitHeight
  width: implicitWidth
  height: implicitHeight

  // Loading by URL avoids importing Quickshell.Hyprland when niri has no Hyprland socket.
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
