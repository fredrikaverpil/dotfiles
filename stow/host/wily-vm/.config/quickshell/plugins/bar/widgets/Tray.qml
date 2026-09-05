import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "TrayModel.js" as TrayModel

// StatusNotifierItem icons. Nothing else in this shell surfaces one, so
// without this an app that closes to the tray -- Signal is the case here --
// keeps running with no way back to its window.
//
// Placed inward of the conditional coffee, so the fixed buttons at the right
// edge never move when an app registers or exits. Sorting outward means a
// newcomer appears at the far left instead of displacing what is showing.
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

      // Resolve a theme name to a file rather than handing the name to the
      // `image://icon/` provider, which looks the theme up at the exact pixel
      // size asked for and fails when the app ships no such size --
      // nm-applet's `nm-device-wired` exists at 16 and not at 20. It answers
      // that miss with a magenta placeholder at Image.Ready rather than an
      // error, so the image's own status cannot tell a missing icon from a
      // real one. A path leaves the scaling to Image, and an unresolvable
      // name leaves `image` empty, which shows the glyph.
      readonly property string themeIcon: TrayModel.themeIconName(modelData.icon)

      shell: tray.shell
      image: themeIcon === ""
        ? (modelData.icon || "")
        : (Quickshell.iconPath(themeIcon, true) || "")
      // An item with no usable pixmap is still worth a slot: it is still a
      // running app, and this is the only way back to it.
      label: "󰘔"
      // The one state the protocol maintains for us. Passive and Active both
      // show -- most apps set Passive once and never touch it again, so
      // hiding those would hide Signal permanently.
      foreground: modelData.status === Status.NeedsAttention
        ? tray.shell.palette.sel
        : tray.shell.palette.fg

      // `onlyMenu` items have no activate action at all, so a left click that
      // called it would be a dead button.
      onActivated: modelData.onlyMenu
        ? tray.panel.openFor(modelData)
        : modelData.activate()
      onSecondary: tray.panel.openFor(modelData)
    }
  }
}
