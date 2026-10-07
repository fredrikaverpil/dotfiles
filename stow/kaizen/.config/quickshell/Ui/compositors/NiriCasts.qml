import QtQuick
import Quickshell.Io

import "NiriCasts.js" as Model

QtObject {
    id: root

    property var casts: []
    readonly property bool sharing: Model.sharing(casts)

    property Process stream: Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]
        // Restarting resynchronises from the stream's initial full state.
        onExited: restart.start()
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    var casts = Model.eventResult(root.casts, JSON.parse(line));
                    if (casts !== root.casts)
                        root.casts = casts;
                } catch (error) {}
            }
        }
    }

    property Timer restart: Timer {
        interval: 1000
        onTriggered: root.stream.running = true
    }
}
