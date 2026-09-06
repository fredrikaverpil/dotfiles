import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "TrayModel.js" as TrayModel

// StatusNotifierItem icons: the only way back to an app that closed to the
// tray. Sits inward of the conditional indicators, so the fixed buttons at the
// right edge never move when an app registers or exits.
Row {
  id: tray

  required property var shell
  required property var panel

  readonly property var items: TrayModel.sortItems(SystemTray.items.values)

  spacing: 4

  Repeater {
    model: tray.items

    Ui.BarButton {
      id: item

      required property var modelData

      // Resolve to a file rather than handing the name to the `image://icon/`
      // provider: that looks up the exact pixel size asked for and answers a
      // miss with a magenta placeholder at Image.Ready, so status cannot tell
      // a missing icon from a real one. A path lets Image scale, and an
      // unresolvable name leaves `image` empty, which shows the glyph.
      readonly property string themeIcon: TrayModel.themeIconName(modelData.icon)

      shell: tray.shell
      image: themeIcon === ""
        ? (modelData.icon || "")
        : (Quickshell.iconPath(themeIcon, true) || "")
      // Fallback for an item with no usable pixmap.
      label: "󰘔"
      // Passive and Active both show: most apps set Passive once and never
      // touch it again.
      foreground: modelData.status === Status.NeedsAttention
        ? tray.shell.palette.sel
        : tray.shell.palette.fg

      // `onlyMenu` items have no activate action, so a left click calling it
      // would be a dead button.
      onActivated: modelData.onlyMenu
        ? tray.panel.openFor(modelData)
        : modelData.activate()
      onSecondary: tray.panel.openFor(modelData)
    }
  }
}
