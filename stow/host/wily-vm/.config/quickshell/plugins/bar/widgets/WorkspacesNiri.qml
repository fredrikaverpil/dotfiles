import QtQuick
import Quickshell
import Quickshell.Io

import "WorkspaceModel.js" as Model

QtObject {
  id: root

  // niri events use global IDs, but focus-workspace and the UI use per-output idx values.
  property int focusedId: -1
  property var ids: []
  property var idxById: ({})
  property var windowCounts: ({})

  function occupied(idx) { return Model.occupied(windowCounts, idx) }

  function apply(result) {
    root.ids = result.ids
    root.idxById = result.idxById
    root.focusedId = result.focusedId
    root.windowCounts = result.windowCounts
    if (result.queryWindows) windowQuery.running = true
  }

  function setWorkspaces(list) {
    apply(Model.eventResult({
      ids: root.ids,
      idxById: root.idxById,
      focusedId: root.focusedId,
      windowCounts: root.windowCounts,
    }, { WorkspacesChanged: { workspaces: list } }))
  }

  function setWindows(list) {
    root.windowCounts = Model.windowCounts(list, root.idxById)
  }

  function handle(event) {
    apply(Model.eventResult({
      ids: root.ids,
      idxById: root.idxById,
      focusedId: root.focusedId,
      windowCounts: root.windowCounts,
    }, event))
  }

  property Process stream: Process {
    running: true
    command: ["niri", "msg", "-j", "event-stream"]
    // Restarting resynchronises from the stream's initial full state.
    onExited: restart.start()
    stdout: SplitParser {
      onRead: function (line) {
        try {
          root.handle(JSON.parse(line))
        } catch (error) {
        }
      }
    }
  }

  property Process windowQuery: Process {
    command: ["niri", "msg", "-j", "windows"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.setWindows(JSON.parse(text))
        } catch (error) {}
      }
    }
  }

  property Timer restart: Timer {
    interval: 1000
    onTriggered: root.stream.running = true
  }
}
