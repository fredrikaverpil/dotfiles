import QtQuick

import "../../../Ui" as Ui

// The bluetooth panel's bar button: rose while off, else coloured by the emptiest connected device.
Ui.BarButton {
    id: button

    required property var service

    foreground: !button.service.powered ? button.shell.palette.rose : button.shell.palette[button.shell.batteryService.levelRole(button.service.lowestBattery)]
    label: button.service.icon
}
