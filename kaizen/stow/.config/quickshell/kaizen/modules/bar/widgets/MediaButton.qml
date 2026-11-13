import QtQuick

import "../../../Ui" as Ui

// The media panel's bar button: play or pause, shown while a track is known.
Ui.BarButton {
    id: button

    required property var service

    visible: button.service.hasMedia
    label: button.service.icon
}
