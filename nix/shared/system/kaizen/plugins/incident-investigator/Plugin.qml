import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui as Ui

// Claude Code investigations of alerts, run by `investigate serve`.
Ui.Plugin {
  id: plugin

  name: "incident-investigator"
  menuItems: ({
    "plugins.incident-investigator": { icon: "󰍉", label: "Incident investigator" },
    "plugins.incident-investigator.open": { icon: "󰕮", label: "Open incident investigator", action: () => plugin.open() },
  })

  // niri raises a window only as it maps, so one open elsewhere, or closed by
  // the compositor while still visible here, is mapped again: focused, on the
  // focused workspace. The selected row takes the keyboard.
  function open() {
    investigations.focusSelected()
    if (window.visible && investigations.Window.active) return
    window.visible = false
    window.visible = true
  }

  IpcHandler {
    target: "incident-investigator"

    function open(): void { plugin.open() }
    function select(id: string): void { investigations.selectedId = id }
    // `investigate` calls it for a new draft and a finished turn's Open button.
    // `qs ipc call <target> show` is parsed as the CLI's own `show`.
    function reveal(id: string): void { investigations.selectedId = id; plugin.open() }
    function filter(tag: string): void { investigations.tagFilter = tag }
    function confirmClear(): void { investigations.confirmingClear = true }
  }

  // A normal window, so it stays up while others have focus; Mod+Q hides it.
  FloatingWindow {
    id: window

    visible: false
    title: "Incident investigator"
    color: plugin.shell.palette.bg
    implicitWidth: 1040
    implicitHeight: 640

    // Follows the shell's text size: laid out at the window's size over the
    // scale, then scaled up to fill it.
    Investigations {
      id: investigations

      readonly property real zoom: plugin.shell.textScale

      x: 12 * zoom
      y: 12 * zoom
      width: window.width / zoom - 24
      height: window.height / zoom - 24
      scale: zoom
      transformOrigin: Item.TopLeft
      shell: plugin.shell
    }
  }
}
