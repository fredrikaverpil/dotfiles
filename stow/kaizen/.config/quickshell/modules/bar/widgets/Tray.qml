import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "TrayModel.js" as TrayModel

Row {
  id: tray

  required property var shell
  required property var panel
  required property string output
  property real maxWidth: Infinity

  readonly property var items: TrayModel.sortItems(SystemTray.items.values)
  readonly property int shown: TrayModel.visibleCount(items.length, maxWidth, 28 * tray.shell.textScale, tray.spacing)
  readonly property var hidden: items.slice(shown)

  // A hidden item's menu hangs from the overflow button.
  function buttonFor(item) {
    const index = items.indexOf(item)
    return index < shown ? buttons.itemAt(index) : overflow
  }

  Component.onCompleted: panel.registerTray(tray)
  Component.onDestruction: panel.unregisterTray(tray)

  spacing: 4

  Repeater {
    id: buttons
    model: tray.items.slice(0, tray.shown)

    Ui.BarButton {
      id: item

      required property var modelData

      readonly property string themeIcon: TrayModel.themeIconName(modelData.icon)

      shell: tray.shell
      // image://icon returns a ready magenta placeholder for a size miss; resolve a file instead.
      image: themeIcon === ""
        ? (modelData.icon || "")
        : (Quickshell.iconPath(themeIcon, true) || "")
      label: "󰘔"
      foreground: modelData.status === Status.NeedsAttention
        ? tray.shell.palette.sel
        : tray.shell.palette.fg

      onActivated: modelData.onlyMenu
        ? tray.panel.openFor(modelData, tray.output)
        : modelData.activate()
      onSecondary: tray.panel.openFor(modelData, tray.output)
      onMiddle: modelData.secondaryActivate()
    }
  }

  Ui.BarButton {
    id: overflow
    shell: tray.shell
    visible: tray.hidden.length > 0
    label: "+" + tray.hidden.length
    foreground: tray.hidden.some(item => item.status === Status.NeedsAttention)
      ? tray.shell.palette.sel
      : tray.shell.palette.fg
    onActivated: tray.shell.menu.popup("tray", tray.output, overflow, row => tray.hidden.includes(row.trayItem))
    onSecondary: tray.shell.menu.popup("tray", tray.output, overflow, row => tray.hidden.includes(row.trayItem))
  }
}
