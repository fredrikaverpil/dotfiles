import QtQuick

import "../../../Ui" as Ui

// The audio panel's bar button: the volume icon, rose while muted.
Ui.BarButton {
    id: button

    required property var service

    foreground: button.service.muted ? button.shell.palette.rose : button.shell.palette.fg
    label: button.service.icon
}
