import QtQuick

import "../../../Ui" as Ui

// Shown by the volume and mic-mute keys.
Ui.Osd {
    id: root

    // The audio service.
    required property var service
    // The audio panel, which shows the change itself while open.
    required property var panel

    property bool mic: false

    icon: mic ? service.micIcon : service.icon
    value: service.volume
    off: service.muted
    text: mic ? (service.micMuted ? "Microphone muted" : "Microphone on") : ""

    Connections {
        target: root.service

        function onAdjusted(mic) {
            if (root.panel.shown)
                return;
            root.mic = mic;
            root.show();
        }
    }
}
