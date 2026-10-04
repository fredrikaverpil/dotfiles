import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "MirrorModel.js" as Model

// niri cannot mirror outputs; wl-mirror shows one fullscreen on another, in a
// transient user unit so it outlives shell reloads.
Item {
    id: root

    property var mirrorState: Model.state("")
    readonly property bool active: mirrorState.pid > 0
    readonly property string source: mirrorState.source
    readonly property string target: mirrorState.target
    property string focused: ""
    property string pendingTarget: ""

    // Mirrors the focused output onto target.
    function start(target) {
        pendingTarget = target;
        focusedQuery.running = true;
    }

    function refreshFocused() {
        focusedQuery.running = true;
    }

    function stop() {
        stopper.running = true;
    }

    function refresh() {
        query.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: focusedQuery
        command: Ui.Compositor.outputs()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const monitor = Ui.Compositor.focusedMonitor(text);
                const target = root.pendingTarget;
                root.pendingTarget = "";
                root.focused = monitor ? monitor.name : "";
                if (!target || !monitor || monitor.name === target)
                    return;
                starter.command = Model.startCommand(monitor.name, target);
                starter.running = true;
            }
        }
    }

    Process {
        id: starter
        onExited: root.refresh()
    }

    Process {
        id: stopper
        command: Model.stopCommand()
        onExited: root.refresh()
    }

    Process {
        id: query
        command: Model.queryCommand()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.mirrorState = Model.state(text);
                if (root.active && !watcher.running) {
                    watcher.command = ["tail", "--pid=" + root.mirrorState.pid, "-f", "/dev/null"];
                    watcher.running = true;
                }
            }
        }
    }

    // Exits with wl-mirror, however it ends (closed window, unplugged output).
    Process {
        id: watcher
        onExited: root.refresh()
    }

    IpcHandler {
        target: "mirror"

        function status(): string {
            return JSON.stringify({
                active: root.active,
                source: root.source,
                target: root.target
            });
        }

        function start(target: string): void {
            root.start(target);
        }

        function stop(): void {
            root.stop();
        }
    }
}
