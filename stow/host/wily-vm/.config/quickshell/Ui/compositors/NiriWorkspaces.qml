import QtQuick
import Quickshell.Io

import "NiriWorkspaces.js" as Model

QtObject {
  id: root

  // niri events use global IDs, but focus-workspace and the UI use per-output idx values.
  property int focusedId: -1
  property var ids: []
  property var idxById: ({})
  property var windowCounts: ({})

  function occupied(idx) { return (windowCounts[idx] || 0) > 0 }

  function handle(event) {
    var result = Model.eventResult({
      ids: root.ids,
      idxById: root.idxById,
      focusedId: root.focusedId,
      windowCounts: root.windowCounts,
    }, event)
    root.ids = result.ids
    root.idxById = result.idxById
    root.focusedId = result.focusedId
    root.windowCounts = result.windowCounts
    if (result.queryWindows) windowQuery.running = true
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
          root.windowCounts = Model.windowCounts(JSON.parse(text), root.idxById)
        } catch (error) {}
      }
    }
  }

  property Timer restart: Timer {
    interval: 1000
    onTriggered: root.stream.running = true
  }
}
