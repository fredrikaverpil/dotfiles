
import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Item {
  id: root

  // The compositor's xkb layouts, read once at start; the shell is the only layout switcher.
  property var names: []

  property int index: 0
  readonly property string name: root.names[root.index] || ""
  readonly property bool isDefault: root.index === 0

  function set(next) {
    if (!(next >= 0 && next < root.names.length) || next === root.index) return
    root.index = next
    Quickshell.execDetached(Ui.Compositor.setLayout(next))
  }

  function next() { root.set((root.index + 1) % root.names.length) }

  Component.onCompleted: query.running = true

  Process {
    id: query
    command: Ui.Compositor.layoutQuery()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.names = Ui.Compositor.layoutNames(text)
        const read = Ui.Compositor.currentLayout(text)
        if (read >= 0 && read < root.names.length) root.index = read
      }
    }
  }

  IpcHandler {
    target: "keyboard"

    function next(): void { root.next() }
    function set(index: int): void { root.set(index) }
    function status(): string {
      return JSON.stringify({ index: root.index, name: root.name, names: root.names })
    }
  }
}
