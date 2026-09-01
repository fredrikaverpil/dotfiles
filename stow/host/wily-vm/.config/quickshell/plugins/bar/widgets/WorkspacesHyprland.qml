import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland's workspace source for Workspaces.qml. Loaded by URL so that this
// file, and the Quickshell.Hyprland import with it, is never compiled under
// niri.
QtObject {
  readonly property int focusedId: Hyprland.focusedWorkspace
    ? Hyprland.focusedWorkspace.id
    : -1

  readonly property var ids: {
    const values = Hyprland.workspaces.values
    const result = []
    for (let i = 0; i < values.length; i++) result.push(values[i].id)
    return result
  }

  function occupied(id) {
    const values = Hyprland.workspaces.values
    for (let i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i].toplevels.values.length > 0
    }
    return false
  }
}
