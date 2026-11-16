import QtQuick

import "../../../Ui" as Ui

// Shown by the brightness keys.
Ui.Osd {
    id: root

    // The brightness service.
    required property var service
    // The display panel, which shows the change itself while open.
    required property var panel

    icon: "󰃠"
    value: service.percent / 100

    Connections {
        target: root.service

        function onAdjusted() {
            if (!root.panel.shown)
                root.show();
        }
    }
}
