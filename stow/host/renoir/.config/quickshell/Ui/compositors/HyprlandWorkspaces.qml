import QtQuick
import Quickshell.Hyprland

// Workspace IDs are global; the output arguments are ignored.
QtObject {
  readonly property int focusedId: Hyprland.focusedWorkspace
    ? Hyprland.focusedWorkspace.id
    : -1

  readonly property var allIds: {
    const values = Hyprland.workspaces.values
    const result = []
    for (let i = 0; i < values.length; i++) result.push(values[i].id)
    return result
  }

  function ids(output) { return allIds }
  function activeId(output) { return focusedId }

  function occupied(id, output) {
    const values = Hyprland.workspaces.values
    for (let i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i].toplevels.values.length > 0
    }
    return false
  }
}
