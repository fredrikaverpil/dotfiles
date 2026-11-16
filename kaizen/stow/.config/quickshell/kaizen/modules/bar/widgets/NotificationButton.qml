import QtQuick

import "../../../Ui" as Ui

// The notification history's bar button: the bell, rose while notifications are held back, with how many it holds.
Ui.BarButton {
    id: button

    required property var service
    readonly property int pending: button.service.historyRows.length

    foreground: button.service.holding ? button.shell.palette.rose : button.shell.palette.fg
    label: (button.service.holding ? "󰂛" : "󰂚") + (button.pending > 0 ? " " + button.pending : "")

    // Blinks while it holds back a critical notification.
    opacity: blinker.running && blinker.dimmed ? 0.2 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
    Timer {
        id: blinker
        property bool dimmed: false
        running: button.service.criticalHeld
        interval: 250
        repeat: true
        onTriggered: blinker.dimmed = !blinker.dimmed
    }
}
