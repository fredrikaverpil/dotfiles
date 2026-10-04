import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "MirrorModel.js" as Model

// niri cannot mirror outputs; wl-mirror shows one fullscreen on another, in
// transient user units so they outlive shell reloads.
Item {
    id: root

    property var mirrors: []
    readonly property bool active: mirrors.length > 0
    // The launcher's source.
    property string focused: ""

    function sourceOf(target) {
        const mirror = mirrors.find(mirror => mirror.target === target);
        return mirror ? mirror.source : "";
    }

    function canMirror(source, target) {
        return Model.canMirror(mirrors, source, target);
    }

    // Replaces target's current source, if any.
    function start(source, target) {
        if (!canMirror(source, target))
            return;
        starter.command = Model.startCommand(source, target);
        focuser.command = Ui.Compositor.focusMonitor(target);
        focuser.running = true;
    }

    function stop(target) {
        stopper.command = Model.stopCommand(target);
        stopper.running = true;
    }

    function stopAll() {
        stopper.command = Model.stopAllCommand();
        stopper.running = true;
    }

    function refresh() {
        query.running = true;
    }

    function refreshFocused() {
        focusedQuery.running = true;
    }

    Component.onCompleted: refresh()

    // niri opens the window on the focused output and ignores wl-mirror's
    // --fullscreen-output; on the source, it would mirror itself.
    Process {
        id: focuser
        onExited: starter.running = true
    }

    Process {
        id: starter
        onExited: root.refresh()
    }

    Process {
        id: stopper
        onExited: root.refresh()
    }

    Process {
        id: query
        command: Model.queryCommand()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.mirrors = Model.mirrors(text);
                const command = Model.watchCommand(root.mirrors);
                // A stale watcher's exit refreshes again, which watches the new set.
                if (watcher.running && JSON.stringify(watcher.command) !== JSON.stringify(command))
                    watcher.running = false;
                else if (root.active && !watcher.running) {
                    watcher.command = command;
                    watcher.running = true;
                }
            }
        }
    }

    // Exits with the first wl-mirror to end, however it ends (closed window, unplugged output).
    Process {
        id: watcher
        onExited: root.refresh()
    }

    Process {
        id: focusedQuery
        command: Ui.Compositor.outputs()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const monitor = Ui.Compositor.focusedMonitor(text);
                root.focused = monitor ? monitor.name : "";
            }
        }
    }

    IpcHandler {
        target: "mirror"

        function status(): string {
            return JSON.stringify({
                mirrors: root.mirrors.map(mirror => ({
                            source: mirror.source,
                            target: mirror.target
                        }))
            });
        }

        function start(source: string, target: string): void {
            root.start(source, target);
        }

        function stop(target: string): void {
            root.stop(target);
        }

        function stopAll(): void {
            root.stopAll();
        }
    }
}
