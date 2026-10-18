import QtQuick
import Quickshell.Io

import "UmbrielEvents.js" as Model

// The one umbriel subscription the shell runs, for the workspace and pinning
// sources.
QtObject {
    id: root

    // umbriel's snapshots, replaced whole on each change.
    property var workspaces: []
    property var windows: []

    property Process stream: Process {
        running: true
        command: ["umbriel", "subscribe", "workspaces,windows"]
        // Restarting resynchronises from the stream's initial snapshots.
        onExited: restart.start()
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    var event = JSON.parse(line);
                    var workspaces = Model.snapshot(event, "workspaces");
                    if (workspaces)
                        root.workspaces = workspaces;
                    var windows = Model.snapshot(event, "windows");
                    if (windows)
                        root.windows = windows;
                } catch (error) {}
            }
        }
    }

    property Timer restart: Timer {
        interval: 1000
        onTriggered: root.stream.running = true
    }
}
