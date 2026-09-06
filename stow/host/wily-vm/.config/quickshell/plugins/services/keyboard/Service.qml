// The shell owns the layout index: every way to switch comes through here, so
// there is no activelayout listener. That holds only while the compositors
// have no toggle of their own -- a `grp:` option in kb_options would switch
// behind this and desync the label.

import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "KeyboardModel.js" as KeyboardModel

Item {
  id: root

  // Same layouts, same order, as `kb_layout` in hypr/hyprland.lua and `layout`
  // in niri/config.kdl. Hardcoded: reaching a short code from what the
  // compositors report needs an xkb description table.
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

  // A shell restart mid-session leaves the compositor on whatever layout it
  // was, so seed from it rather than assuming the default.
  Component.onCompleted: query.running = true

  Process {
    id: query
    command: Ui.Compositor.layoutQuery()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const read = KeyboardModel.currentIndex(text, Ui.Compositor.niri)
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
