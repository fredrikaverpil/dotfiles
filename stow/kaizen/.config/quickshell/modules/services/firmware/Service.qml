import QtQuick
import Quickshell
import Quickshell.Io

import "FirmwareModel.js" as Model
import "Fwupd.js" as Fwupd

Item {
    id: root

    // Each backend reads its own daemon; the shell lists updates and never
    // applies them, since installing can need AC power, a reboot or root.
    readonly property var known: ({
            fwupd: Fwupd
        })
    // Set from the host's Nix config: only the backends it enables run.
    readonly property var backends: Model.backends(Quickshell.env("KAIZEN_FIRMWARE_BACKENDS"), Object.keys(known))

    // backend -> { updates, error } from its last check.
    property var results: ({})
    readonly property var merged: Model.merge(backends, results)
    readonly property var updates: Model.order(merged.updates)
    readonly property var errors: merged.errors
    // Milliseconds since the epoch; 0 before the first check finishes.
    property real lastChecked: 0
    readonly property bool checking: probes.instances.some(instance => instance.running)

    // The backends read local metadata, so a check costs no network.
    function refresh() {
        probes.instances.forEach(instance => {
            if (!instance.running)
                instance.start();
        });
    }

    function update(id) {
        return updates.find(update => update.id === id) || null;
    }

    function copyCommand(id) {
        const found = update(id);
        if (!found)
            return false;
        Quickshell.execDetached(["wl-copy", "--", found.command]);
        return true;
    }

    function openPage(id) {
        const found = update(id);
        if (!found || found.url === "")
            return false;
        Quickshell.execDetached(["xdg-open", found.url]);
        return true;
    }

    function status() {
        return JSON.stringify({
            backends: backends,
            checking: checking,
            lastChecked: lastChecked,
            updates: updates,
            errors: errors
        });
    }

    Variants {
        id: probes
        model: root.backends

        Process {
            id: probe

            required property string modelData
            readonly property var backend: root.known[modelData]
            // A result needs the exit code and both streams, in any order.
            property var code: null
            property string out: ""
            property string err: ""
            property int streams: 0

            function start() {
                code = null;
                streams = 0;
                running = true;
            }

            function finish() {
                if (code === null || streams < 2)
                    return;
                const result = code === 0 ? backend.parse(out) : {
                    updates: [],
                    error: err.trim() || modelData + " exited with " + code
                };
                root.results = Object.assign({}, root.results, {
                    [modelData]: result
                });
                root.lastChecked = Date.now();
            }

            command: backend.command()
            stdout: StdioCollector {
                waitForEnd: true
                onStreamFinished: {
                    probe.out = text;
                    probe.streams++;
                    probe.finish();
                }
            }
            stderr: StdioCollector {
                waitForEnd: true
                onStreamFinished: {
                    probe.err = text;
                    probe.streams++;
                    probe.finish();
                }
            }
            onExited: function (exitCode) {
                probe.code = exitCode;
                probe.finish();
            }
            Component.onCompleted: start()
        }
    }

    // Daily by the wall clock: a Timer's clock stops during suspend.
    // fwupd-refresh.timer downloads metadata twice a day.
    Timer {
        interval: 60 * 60 * 1000
        repeat: true
        running: root.backends.length > 0
        onTriggered: {
            if (Date.now() - root.lastChecked >= 24 * 60 * 60 * 1000)
                root.refresh();
        }
    }
}
