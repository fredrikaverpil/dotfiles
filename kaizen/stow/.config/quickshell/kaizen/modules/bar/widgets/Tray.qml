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
    // One tray button replaces the items when they do not all fit.
    readonly property bool collapsed: !TrayModel.fits(items.length, maxWidth, 28 * tray.shell.textScale, tray.spacing)

    // Collapsed, every item's menu hangs from the tray button.
    function buttonFor(item) {
        return collapsed ? trayButton : buttons.itemAt(items.indexOf(item));
    }

    Component.onCompleted: panel.registerTray(tray)
    Component.onDestruction: panel.unregisterTray(tray)

    spacing: 4

    Repeater {
        id: buttons
        model: tray.collapsed ? [] : tray.items

        Ui.BarButton {
            id: item

            required property var modelData

            readonly property string themeIcon: TrayModel.themeIconName(modelData.icon)

            shell: tray.shell
            // image://icon returns a ready magenta placeholder for a size miss; resolve a file instead.
            image: themeIcon === "" ? (modelData.icon || "") : (Quickshell.iconPath(themeIcon, true) || "")
            label: "󰘔"
            foreground: modelData.status === Status.NeedsAttention ? tray.shell.palette.sel : tray.shell.palette.fg

            onActivated: modelData.onlyMenu ? tray.panel.openFor(modelData, tray.output) : modelData.activate()
            onSecondary: tray.panel.openFor(modelData, tray.output)
            onMiddle: modelData.secondaryActivate()
        }
    }

    Ui.BarButton {
        id: trayButton
        shell: tray.shell
        visible: tray.collapsed
        label: "󰘔"
        foreground: tray.items.some(item => item.status === Status.NeedsAttention) ? tray.shell.palette.sel : tray.shell.palette.fg
        onActivated: tray.shell.menu.popup("tray", tray.output, trayButton)
        onSecondary: tray.shell.menu.popup("tray", tray.output, trayButton)
    }
}
