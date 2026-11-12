import QtQuick

import "../../../Ui" as Ui

// The firmware panel's bar indicator, shown while an update is pending.
Ui.BarButton {
    id: button

    required property var service

    visible: button.service.updates.length > 0
    // Wood even when urgent: updates can wait for a convenient reboot.
    foreground: button.shell.palette.wood
    label: "󰚰"
}
