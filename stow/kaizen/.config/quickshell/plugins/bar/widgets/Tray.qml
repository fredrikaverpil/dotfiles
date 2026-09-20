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

  readonly property var items: TrayModel.sortItems(SystemTray.items.values)

  function buttonFor(item) {
    return buttons.itemAt(items.indexOf(item))
  }

  Component.onCompleted: panel.registerTray(tray)
  Component.onDestruction: panel.unregisterTray(tray)

  spacing: 4

  Repeater {
    id: buttons
    model: tray.items

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
}
