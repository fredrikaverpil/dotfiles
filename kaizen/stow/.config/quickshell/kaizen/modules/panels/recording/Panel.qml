import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    readonly property bool active: service.selecting || service.busy

    cardWidth: view.cardWidth
    keyNavigation: view.keyNavigation

    function record(dnd) {
        close();
        service.start();
        if (dnd && active)
            shell.notifications.holdDoNotDisturb("recording", true);
    }

    function restore() {
        if (!active)
            shell.notifications.holdDoNotDisturb("recording", false);
    }

    onShownChanged: if (shown) {
        service.refreshCameras();
        view.reset();
    }

    // Later: active dips while the selector hands over to the countdown.
    onActiveChanged: if (!active)
        Qt.callLater(restore)

    IpcHandler {
        target: "recording"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        // Stops or cancels while busy, so one key both opens the panel and ends the recording.
        function toggle(): void {
            root.service.busy ? root.service.stop() : root.toggle();
        }
        function start(): void {
            root.service.start();
        }
        // Selects a region and saves a screenshot of it.
        function screenshot(): void {
            root.service.screenshot();
        }
        // Saves a screenshot of the focused "screen" or "window".
        function shoot(mode: string): void {
            root.service.shoot(mode);
        }
        function stop(): void {
            root.service.stop();
        }
        function pause(): void {
            root.service.togglePause();
        }
        // Records WxH+X+Y (logical, global) at once, silently; returns the file or "".
        function capture(geometry: string): string {
            return root.service.capture(geometry);
        }
        function status(): string {
            return JSON.stringify({
                selecting: root.service.selecting,
                region: root.service.region,
                recording: root.service.recording,
                paused: root.service.paused,
                countdown: root.service.countdown,
                seconds: root.service.seconds,
                file: root.service.file,
                monitor: root.service.activeMonitor,
                camera: root.service.activeCamera,
                cameraFraction: root.service.cameraFraction,
                mic: root.service.activeMic,
                desktop: root.service.desktop,
                monitors: root.service.monitors,
                cameras: root.service.cameras
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onRecordRequested: dnd => root.record(dnd)
    }
}
