pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "CompositorModel.js" as Model

Singleton {
  id: root

  readonly property var backend: Model.select(Quickshell.env)
  readonly property string name: backend.name
  readonly property bool releaseExclusiveFocus: backend.releaseExclusiveFocus
  readonly property url workspaceSource: Qt.resolvedUrl("compositors/" + backend.workspaceComponent)
  readonly property string themeConfig: Quickshell.env("HOME") + backend.themeConfig

  function dpms(on) { return backend.dpms(on) }
  function closeWindow() { return backend.closeWindow() }
  function screenshot(mode) { return backend.screenshot(mode) }
  function focusWorkspace(id, output) { return backend.focusWorkspace(id, output) }
  function outputs() { return backend.outputs() }
  function focusedMonitor(raw) { return backend.focusedMonitor(raw) }
  function themeEdits(palette) { return backend.themeEdits(palette) }
  function layoutQuery() { return backend.layoutQuery() }
  function currentLayout(raw) { return backend.currentLayout(raw) }
  function setLayout(index) { return backend.setLayout(index) }

  IpcHandler {
    target: "compositor"

    function status(): string {
      return JSON.stringify({
        id: root.backend.id,
        name: root.name,
        workspaceSource: root.workspaceSource.toString(),
        releaseExclusiveFocus: root.releaseExclusiveFocus
      })
    }
  }
}
