import QtQuick
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "../../bar/widgets/TrayModel.js" as TrayModel

Ui.ContextMenu {
  id: root

  property var item: null
  // Bar Tray widgets, one per output.
  property var trays: []

  // The item's primary action heads its root menu, so the menu reaches everything.
  headRows: item && !item.onlyMenu
    ? [
      { text: "Activate", enabled: true, isSeparator: false, triggered: () => root.item.activate() },
      { isSeparator: true, enabled: true },
    ]
    : []

  function registerTray(tray) {
    if (trays.indexOf(tray) < 0) trays = trays.concat([tray])
  }

  function unregisterTray(tray) {
    trays = trays.filter(candidate => candidate !== tray)
  }

  // output is the bar's screen name; without one the menu opens on the focused output.
  function openFor(trayItem, output) {
    if (shown && item === trayItem) {
      close()
      return
    }
    if (!trayItem || !trayItem.hasMenu) return
    item = trayItem
    popup(trayItem.menu, output, screenName => {
      const tray = trays.find(candidate => candidate.output === screenName)
      const button = tray ? tray.buttonFor(trayItem) : null
      const point = button ? button.mapToItem(null, 0, 0) : null
      return point ? { below: true, x: point.x, width: button.width } : null
    })
  }

  IpcHandler {
    target: "tray"

    function menu(id: string): void {
      const found = SystemTray.items.values.find(item => String(item.id) === id)
      if (found) root.openFor(found)
    }
    function list(): string {
      return TrayModel.sortItems(SystemTray.items.values)
        .map(item => item.id + "\t" + TrayModel.labelFor(item)).join("\n")
    }
    function close(): void { root.close() }
  }
}
