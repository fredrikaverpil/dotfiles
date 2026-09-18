import QtQuick
import Quickshell
import Quickshell.Io

import "ClipboardModel.js" as Model

Item {
  id: root

  readonly property int limit: 50
  // In memory only: history ends with the shell.
  property var history: []

  function copy(text) { Quickshell.execDetached(["wl-copy", "--", text]) }

  function clear() { history = [] }

  // Password managers (Proton Pass, 1Password) mark secrets with
  // x-kde-passwordManagerHint; those offers are never read.
  Process {
    running: true
    command: ["wl-paste", "--type", "text", "--watch", "sh", "-c",
      "wl-paste --list-types | grep -qx x-kde-passwordManagerHint && exit; jq -cRs ."]
    stdout: SplitParser {
      onRead: line => {
        let text
        try {
          text = JSON.parse(line)
        } catch (e) {
          return
        }
        root.history = Model.add(root.history, text, new Date(), root.limit)
      }
    }
  }
}
