import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.isSink && !node.isStream) : []
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property var sources: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.audio && !node.isSink && !node.isStream) : []
    readonly property bool micMuted: sources.length > 0 && sources.every(node => node.audio.muted)
    readonly property string icon: muted || volume <= 0 ? "󰖁" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"

    // Emitted by the volume and mic-mute keys, for the OSD.
    signal adjusted(bool mic)

    cardWidth: view.cardWidth
    keyNavigation: view.keyNavigation

    function label(node) {
        return node ? (node.nickname || node.description || node.name || "Unknown") : "";
    }

    function setVolume(value) {
        if (!sink || !sink.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute() {
        const muted = !micMuted;
        for (const node of sources)
            node.audio.muted = muted;
    }

    // Serialized so a quick toggle cannot land an older value last.
    function syncMicLed() {
        if (micLed.running)
            return;
        micLed.value = micMuted ? "1" : "0";
        micLed.running = true;
    }

    onMicMutedChanged: syncMicLed()
    Component.onCompleted: syncMicLed()

    // Inputs, per-app volumes and profiles are set in pwvucontrol.
    function openSettings() {
        close();
        Quickshell.execDetached(["pwvucontrol"]);
    }

    // Selecting the current default would store it as the user's choice, ahead of an absent headset.
    function setDefault(node) {
        if (node && node !== sink)
            Pipewire.preferredDefaultAudioSink = node;
    }

    // PipeWire node properties do not bind until their objects are tracked.
    PwObjectTracker {
        objects: root.sinks.concat(root.sources)
    }

    // The kernel drives platform::micmute from ALSA capture switches, which miss other sources.
    Process {
        id: micLed
        property string value: "0"
        command: ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto", "org.freedesktop.login1.Session", "SetBrightness", "ssu", "leds", "platform::micmute", value]
        onExited: if (value !== (root.micMuted ? "1" : "0"))
            root.syncMicLed()
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
            root.setVolume(root.volume + 0.05);
            root.adjusted(false);
        }
        function down(): void {
            root.setVolume(root.volume - 0.05);
            root.adjusted(false);
        }
        function mute(): void {
            root.toggleMute();
            root.adjusted(false);
        }
        function micMute(): void {
            root.toggleMicMute();
            root.adjusted(true);
        }
        function setVolume(percent: int): void {
            root.setVolume(percent / 100);
        }
        function status(): string {
            return JSON.stringify({
                volume: Math.round(root.volume * 100),
                muted: root.muted,
                sink: root.label(root.sink),
                micMuted: root.micMuted,
                sources: root.sources.map(node => root.label(node))
            });
        }
    }

    View {
        id: view
        shell: root.shell
        audio: root
    }
}
