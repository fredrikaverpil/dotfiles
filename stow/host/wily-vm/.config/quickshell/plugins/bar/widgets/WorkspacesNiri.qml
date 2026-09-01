import QtQuick
import Quickshell
import Quickshell.Io

// niri's workspace source for Workspaces.qml. Quickshell has no niri module,
// so this reads the compositor's own event stream: one JSON object per line on
// stdout, with the full current state sent up front, so no separate query is
// needed at startup.
QtObject {
  id: root

  property int focusedId: -1
  property var ids: []
  // Workspace id -> window count, maintained from the window events. niri's
  // workspace objects do not carry one.
  property var windowCounts: ({})

  function occupied(id) { return (windowCounts[id] || 0) > 0 }

  function setWorkspaces(list) {
    var next = []
    for (var i = 0; i < list.length; i++) {
      next.push(list[i].id)
      if (list[i].is_focused) root.focusedId = list[i].id
    }
    next.sort(function (a, b) { return a - b })
    root.ids = next
  }

  function setWindows(list) {
    var counts = {}
    for (var i = 0; i < list.length; i++) {
      var ws = list[i].workspace_id
      if (ws !== null && ws !== undefined) counts[ws] = (counts[ws] || 0) + 1
    }
    root.windowCounts = counts
  }

  function handle(event) {
    if (event.WorkspacesChanged) {
      setWorkspaces(event.WorkspacesChanged.workspaces)
    } else if (event.WorkspaceActivated) {
      // Only the focused flag moves; the id set is unchanged.
      if (event.WorkspaceActivated.focused) root.focusedId = event.WorkspaceActivated.id
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
