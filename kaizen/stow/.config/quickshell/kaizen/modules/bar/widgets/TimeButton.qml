import QtQuick

import "../../../Ui" as Ui

// The time panel's bar button: the time.
Ui.BarButton {
    id: button

    required property date date

    label: Qt.formatDateTime(button.date, "HH:mm")
}
