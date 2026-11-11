import QtQuick

import "../../../Ui" as Ui

// The clock panel's bar button: the time, pulsing on the hour.
Ui.BarButton {
    id: button

    required property date date

    label: Qt.formatDateTime(button.date, "HH:mm")
    onLabelChanged: if (label.endsWith(":00"))
        hourPulse.restart()

    SequentialAnimation {
        id: hourPulse
        loops: 3
        NumberAnimation {
            target: button
            property: "scale"
            to: 1.25
            duration: 200
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: button
            property: "scale"
            to: 1.0
            duration: 200
            easing.type: Easing.InQuad
        }
    }
}
