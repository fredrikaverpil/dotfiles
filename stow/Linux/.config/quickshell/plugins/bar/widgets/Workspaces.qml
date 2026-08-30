import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
  id: root

  property color foreground: "#B4BDC3"
  property color selection: "#3D4042"

  function workspaceById(id) {
    const values = Hyprland.workspaces.values
    for (let i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    const ids = [1, 2, 3, 4, 5]
    const values = Hyprland.workspaces.values

    for (let i = 0; i < values.length; i++) {
      const id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort((left, right) => left - right)
    return ids
  }

  function focusWorkspace(id) {
    Quickshell.execDetached([
      "hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + id + "\" })",
    ])
  }

  implicitWidth: workspaces.implicitWidth
  implicitHeight: workspaces.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Row {
    id: workspaces
    spacing: 2

    Repeater {
      model: root.workspaceIds()

      delegate: Rectangle {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null
          && Hyprland.focusedWorkspace.id === modelData

        width: 20
        height: 24
        radius: 4
        color: mouse.containsMouse ? root.selection : "transparent"
        opacity: occupied || focused ? 1 : 0.5

        Text {
          anchors.centerIn: parent
          color: root.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
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
