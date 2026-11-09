import QtQuick

import "../../../Ui" as Ui

// The battery panel's bar button: icon and charge, wood then rose as it runs low.
Ui.BarButton {
    id: button

    required property var service

    visible: button.service.present
    implicitWidth: visible ? 64 * button.shell.textScale : 0
    foreground: !button.service.onBattery ? button.shell.palette.fg : button.service.percentage <= button.service.lowLevel ? button.shell.palette.rose : button.service.percentage <= button.service.warnLevel ? button.shell.palette.wood : button.shell.palette.fg
    label: button.service.icon + " " + button.service.percentage + "%"
}
