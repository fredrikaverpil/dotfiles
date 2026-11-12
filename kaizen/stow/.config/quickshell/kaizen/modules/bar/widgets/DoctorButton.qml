import QtQuick

import "../../../Ui" as Ui

// The doctor panel's bar indicator, shown while `kaizen doctor` reports anything.
Ui.BarButton {
    id: button

    required property var service

    visible: button.service.findings.length > 0 || button.service.failure !== ""
    foreground: button.service.counts.errors > 0 || button.service.failure !== "" ? button.shell.palette.rose : button.shell.palette.wood
    label: "󰃤"
}
