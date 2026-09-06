import QtQuick
import Quickshell
import Quickshell.Io

// niri's workspace source for Workspaces.qml. Quickshell has no niri module,
// so this reads niri's event stream: one JSON object per line, with the full
// current state sent up front.
QtObject {
  id: root

  // Everything exposed here is the per-output index (the number on the key,
  // and what `focus-workspace` takes), not niri's global `id` counter.
  property int focusedId: -1
  property var ids: []
  // niri workspace id -> index, so the events that carry only an id can be
  // translated.
  property var idxById: ({})
  // Workspace index -> window count. niri's workspace objects do not carry one.
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
    // The counts are keyed by index, so a renumbering invalidates them.
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
      // Only the focused flag moves; a workspace new to us arrives with its
      // own WorkspacesChanged.
      var idx = root.idxById[event.WorkspaceActivated.id]
      if (event.WorkspaceActivated.focused && idx !== undefined) root.focusedId = idx
    } else if (event.WindowsChanged) {
      setWindows(event.WindowsChanged.windows)
    } else if (event.WindowOpenedOrChanged || event.WindowClosed
        || event.WindowLayoutsChanged) {
      // Counting incrementally would need the window's previous workspace,
      // which the event does not carry.
      windowQuery.running = true
    }
  }

  property Process stream: Process {
    running: true
    command: ["niri", "msg", "-j", "event-stream"]
    // The stream can end quietly while the compositor stays up, stranding the
    // widget. A restart resends full state, so it is also a resync.
    onExited: restart.start()
    stdout: SplitParser {
      onRead: function (line) {
        try {
          root.handle(JSON.parse(line))
        } catch (error) {
          // A line that does not parse is one event lost, not a reason to drop
          // the stream.
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
