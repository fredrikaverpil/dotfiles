import QtQuick
import Quickshell

import "../../../Ui" as Ui

// The time, large and centred on every output, when the hour strikes. Held back under DnD, which is for sharing and
// recording the screen, and while locked or curtained. A strike missed asleep is not shown on resume.
Scope {
    id: root

    required property var shell
    // The timezone panel, whose IPC shows this on demand.
    required property var panel

    function strike() {
        if (shell.notifications.doNotDisturb || shell.lock.locked || shell.curtain.active)
            return;
        osd.show();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: if (date.getMinutes() === 0)
            root.strike()
    }

    Connections {
        target: root.panel

        function onHourRequested() {
            osd.show();
        }
    }

    Ui.LargeOsd {
        id: osd
        shell: root.shell
        namespace: "kaizen-hour"
        headline: Qt.formatDateTime(clock.date, "HH:mm")
        detail: Qt.formatDateTime(clock.date, "dddd d MMMM")
    }
}
