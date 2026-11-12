import QtQuick

import "../../../Ui" as Ui

// The weather panel's bar button: the sky's icon, then the temperature once a forecast is in.
Ui.BarButton {
    id: button

    required property var service

    implicitWidth: 58 * button.shell.textScale
    label: button.service.ready ? button.service.icon + " " + button.service.temperature : button.service.icon
}
