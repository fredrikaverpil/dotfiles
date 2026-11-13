import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: 400
    keyNavigation: true

    // Inputs, per-app volumes and profiles are set in pwvucontrol.
    function openSettings() {
        close();
        Quickshell.execDetached(["pwvucontrol"]);
    }

    IpcHandler {
        target: "audio"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function up(): void {
            root.service.setVolume(root.service.volume + 0.05);
            root.service.adjusted(false);
        }
        function down(): void {
            root.service.setVolume(root.service.volume - 0.05);
            root.service.adjusted(false);
        }
        function mute(): void {
            root.service.toggleMute();
            root.service.adjusted(false);
        }
        function micMute(): void {
            root.service.toggleMicMute();
            root.service.adjusted(true);
        }
        function setVolume(percent: int): void {
            root.service.setVolume(percent / 100);
        }
        function status(): string {
            return JSON.stringify({
                volume: Math.round(root.service.volume * 100),
                muted: root.service.muted,
                sink: root.service.label(root.service.sink),
                micMuted: root.service.micMuted,
                sources: root.service.sources.map(node => root.service.label(node))
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onSettingsRequested: root.openSettings()
    }
}
