import QtQuick
import Quickshell
import Quickshell.Io

// niri's workspace source for Workspaces.qml. Quickshell has no niri module,
// so this reads the compositor's own event stream: one JSON object per line on
// stdout, with the full current state sent up front, so no separate query is
// needed at startup.
QtObject {
  id: root

  // Everything exposed here is the per-output index, the number on the key and
  // the one `focus-workspace` takes. niri's own `id` is a global counter that
  // never renumbers, so the two diverge as soon as a workspace is dropped.
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
      // Only the focused flag moves; the id set is unchanged. The event names
      // the workspace by id, and a workspace new to us arrives with its own
      // WorkspacesChanged.
      var idx = root.idxById[event.WorkspaceActivated.id]
      if (event.WorkspaceActivated.focused && idx !== undefined) root.focusedId = idx
    } else if (event.WindowsChanged) {
      setWindows(event.WindowsChanged.windows)
    } else if (event.WindowOpenedOrChanged || event.WindowClosed
        || event.WindowLayoutsChanged) {
      // Counting from a single event would need the window's previous
      // workspace, which the event does not carry. Re-ask instead; these are
      // not frequent enough for the extra process to matter.
      windowQuery.running = true
    }
  }

  property Process stream: Process {
    running: true
    command: ["niri", "msg", "-j", "event-stream"]
    // The stream has been seen to end quietly while the compositor stays up,
    // which strands the widget on its last state. Re-establishing it costs a
    // full state resend, so a restart is also a resync.
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
