import QtQuick
import Quickshell.Io

import "NiriWorkspaces.js" as Model

QtObject {
  id: root

  // niri events use global IDs, but focus-workspace and the UI use per-output idx values.
  property var workspaces: ({})
  property var activeByOutput: ({})
  property var windowCounts: ({})

  function ids(output) { return Model.ids(workspaces, output) }
  function activeId(output) { return output in activeByOutput ? activeByOutput[output] : -1 }
  function occupied(idx, output) { return Model.occupied(workspaces, windowCounts, output, idx) }

  function handle(event) {
    var result = Model.eventResult({
      workspaces: root.workspaces,
      activeByOutput: root.activeByOutput,
      windowCounts: root.windowCounts,
    }, event)
    root.workspaces = result.workspaces
    root.activeByOutput = result.activeByOutput
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
          root.windowCounts = Model.windowCounts(JSON.parse(text))
        } catch (error) {}
      }
    }
  }

  property Timer restart: Timer {
    interval: 1000
    onTriggered: root.stream.running = true
  }
}
