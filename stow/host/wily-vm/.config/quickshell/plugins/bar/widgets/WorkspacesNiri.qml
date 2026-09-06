import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  // niri events use global IDs, but focus-workspace and the UI use per-output idx values.
  property int focusedId: -1
  property var ids: []
  property var idxById: ({})
  property var windowCounts: ({})

  function occupied(idx) { return (windowCounts[idx] || 0) > 0 }

  function setWorkspaces(list) {
    var next = []
    var map = {}
    for (var i = 0; i < list.length; i++) {
      map[list[i].id] = list[i].idx
      next.push(list[i].idx)
      if (list[i].is_focused) root.focusedId = list[i].idx
    }
    next.sort(function (a, b) { return a - b })
    root.ids = next
    root.idxById = map
    windowQuery.running = true
  }

  function setWindows(list) {
    var counts = {}
    for (var i = 0; i < list.length; i++) {
      var idx = root.idxById[list[i].workspace_id]
      if (idx !== undefined) counts[idx] = (counts[idx] || 0) + 1
    }
    root.windowCounts = counts
  }

  function handle(event) {
    if (event.WorkspacesChanged) {
      setWorkspaces(event.WorkspacesChanged.workspaces)
    } else if (event.WorkspaceActivated) {
      var idx = root.idxById[event.WorkspaceActivated.id]
      if (event.WorkspaceActivated.focused && idx !== undefined) root.focusedId = idx
    } else if (event.WindowsChanged) {
      setWindows(event.WindowsChanged.windows)
    } else if (event.WindowOpenedOrChanged || event.WindowClosed
        || event.WindowLayoutsChanged) {
      windowQuery.running = true
    }
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
