// Keyboard layout. Omarchy's counterpart is a bar widget
// (shell/plugins/bar/widgets/KeyboardLayout.qml) that owns its own state; this
// is a service because the bar, the launcher and an IPC chord all reach it.
//
// The shell owns the index. Every way to switch -- the bar button, the
// launcher, the SUPER + CTRL + K chord -- comes through here, so there is no
// activelayout listener and no second niri event-stream. That holds only while
// the compositors have no layout toggle of their own: adding a `grp:` option
// to kb_options would switch behind this and desync the label.

import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "KeyboardModel.js" as KeyboardModel

Item {
  id: root

  // Same layouts, same order, as `kb_layout` in hypr/hyprland.lua and `layout`
  // in niri/config.kdl. Both compositors can be asked for the list, but only
  // in shapes that need an xkb description table to reach a short code from:
  // Omarchy shells out to `xkbcli list --load-exotic`, caelestia xmllints
  // base.xml, DankMaterialShell ships a hand-written LANG_CODES map. Two
  // entries are not worth any of those.
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
  // was, so seed from it rather than assuming the configured default.
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
