import QtQuick
import Quickshell.Io

import "NiriEvents.js" as Model

// The one niri event stream the shell runs, for the workspace, cast and
// pinning sources.
QtObject {
    id: root

    // niri events use global IDs, but focus-workspace and the UI use per-output idx values.
    property var workspaces: ({})
    property var windows: ({})
    property var casts: []

    // Each event, once the state above took it.
    signal received(var event)

    property Process stream: Process {
        running: true
        command: ["niri", "msg", "-j", "event-stream"]
        // Restarting resynchronises from the stream's initial full state.
        onExited: restart.start()
        stdout: SplitParser {
            onRead: function (line) {
                var event;
                try {
                    event = JSON.parse(line);
                } catch (error) {
                    return;
                }
                var state = Model.eventResult({
                    workspaces: root.workspaces,
                    windows: root.windows,
                    casts: root.casts
                }, event);
                if (state.workspaces !== root.workspaces)
                    root.workspaces = state.workspaces;
                if (state.windows !== root.windows)
                    root.windows = state.windows;
                if (state.casts !== root.casts)
                    root.casts = state.casts;
                root.received(event);
            }
        }
    }

    property Timer restart: Timer {
        interval: 1000
        onTriggered: root.stream.running = true
    }
}
