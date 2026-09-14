import QtQuick
import Quickshell.Io

import "CalendarModel.js" as Model

// Queried on demand; dcal owns sync.
Item {
  id: root

  property var days: []
  property bool failed: false
  property var requestedAt: new Date()

  readonly property bool busy: list.running

  function refresh() {
    if (list.running) return
    requestedAt = new Date()
    list.command = Model.listCommand(requestedAt)
    list.running = true
  }

  Process {
    id: list
    stdout: StdioCollector {
      onStreamFinished: {
        const days = Model.parse(text, root.requestedAt)
        root.failed = days === null
        root.days = days || []
      }
    }
  }
}
