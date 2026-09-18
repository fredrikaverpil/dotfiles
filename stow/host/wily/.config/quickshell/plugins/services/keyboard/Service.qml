
import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Item {
  id: root

  // Order must match both compositor configurations; the shell is the only layout switcher.
  readonly property var codes: ["US", "SE"]

  property int index: 0
  readonly property string code: root.codes[root.index] || ""
  readonly property bool isDefault: root.index === 0

  function set(next) {
    if (next < 0 || next >= root.codes.length || next === root.index) return
    root.index = next
    Quickshell.execDetached(Ui.Compositor.setLayout(next))
  }

  function next() { root.set((root.index + 1) % root.codes.length) }

  Component.onCompleted: query.running = true

  Process {
    id: query
    command: Ui.Compositor.layoutQuery()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const read = Ui.Compositor.currentLayout(text)
        if (read >= 0 && read < root.codes.length) root.index = read
      }
    }
  }

  IpcHandler {
    target: "keyboard"

    function next(): void { root.next() }
    function set(index: int): void { root.set(index) }
    function status(): string {
      return JSON.stringify({ index: root.index, code: root.code, codes: root.codes })
    }
  }
}
