import QtQuick
import Quickshell

import "../../../Ui" as Ui
import "../../../Ui/compositors" as Compositors
import "WorkspaceModel.js" as Model

Item {
  id: root

  required property string output
  property color foreground: "#B4BDC3"
  property color selection: "#3D4042"
  property real fontScale: 1

  function workspaceIds() {
    return Model.workspaceIds(source.ids(root.output))
  }

  function focusWorkspace(id) {
    Quickshell.execDetached(Ui.Compositor.focusWorkspace(id, root.output))
  }

  implicitWidth: workspaces.implicitWidth
  implicitHeight: workspaces.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Compositors.NiriWorkspaces {
    id: source
  }

  Row {
    id: workspaces
    spacing: 2

    Repeater {
      model: root.workspaceIds()

      delegate: Rectangle {
        required property int modelData

        readonly property bool occupied: source.occupied(modelData, root.output)
        readonly property bool focused: source.activeId(root.output) === modelData

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
          font.family: Ui.Fonts.mono
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
