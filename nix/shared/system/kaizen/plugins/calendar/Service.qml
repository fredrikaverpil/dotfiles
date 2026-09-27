import QtQuick
import Quickshell.Io

import "CalendarModel.js" as Model

// Queried on demand; dcal owns sync.
Item {
  id: root

  property var days: []
  property bool failed: false
  property var requestedAt: new Date()
  property var tags: ({})

  readonly property bool busy: calendars.running || list.running

  function refresh() {
    if (busy) return
    requestedAt = new Date()
    calendars.running = true
  }

  // Events carry only a calendar id; the tag comes from its calendar.
  Process {
    id: calendars
    command: ["dcal", "--json", "ipc", "calendars.list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.tags = Model.tags(text)
        list.command = Model.listCommand(root.requestedAt)
        list.running = true
      }
    }
  }

  Process {
    id: list
    stdout: StdioCollector {
      onStreamFinished: {
        const days = Model.parse(text, root.requestedAt, root.tags)
        root.failed = days === null
        root.days = days || []
      }
    }
  }
}
