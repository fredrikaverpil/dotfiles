import QtQuick

import "../../../Ui" as Ui

// The notification history's bar button: the bell, rose while notifications are held back, with how many it holds.
Ui.BarButton {
    id: button

    required property var service
    readonly property int pending: button.service.historyRows.length

    foreground: button.service.holding ? button.shell.palette.rose : button.shell.palette.fg
    label: (button.service.holding ? "󰂛" : "󰂚") + (button.pending > 0 ? " " + button.pending : "")

    // Blinks while holding is overdue, faster while it holds back a critical one.
    opacity: blinker.running && blinker.dimmed ? 0.2 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }
    Timer {
        id: blinker
        property bool dimmed: false
        running: button.service.holdOverdue || button.service.criticalHeld
        interval: button.service.criticalHeld ? 250 : 800
        repeat: true
        onTriggered: blinker.dimmed = !blinker.dimmed
    }
}
