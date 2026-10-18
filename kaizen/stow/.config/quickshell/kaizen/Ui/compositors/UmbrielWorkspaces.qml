import QtQuick
import Quickshell.Io

import "UmbrielWorkspaces.js" as Model

QtObject {
    id: root

    // umbriel's workspace snapshots, replaced whole on each change.
    property var workspaces: []

    function ids(output) {
        return Model.ids(workspaces, output);
    }
    function activeId(output) {
        return Model.activeId(workspaces, output);
    }
    function occupied(idx, output) {
        return Model.occupied(workspaces, output, idx);
    }

    property Process stream: Process {
        running: true
        command: ["umbriel", "subscribe", "workspaces"]
        // Restarting resynchronises from the stream's initial snapshot.
        onExited: restart.start()
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    var list = Model.snapshot(JSON.parse(line));
                    if (list)
                        root.workspaces = list;
                } catch (error) {}
            }
        }
    }

    property Timer restart: Timer {
        interval: 1000
        onTriggered: root.stream.running = true
    }
}
