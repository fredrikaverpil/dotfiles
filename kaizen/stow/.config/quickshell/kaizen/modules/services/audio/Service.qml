import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

import "AudioModel.js" as AudioModel

// The default sink's and source's volume and mute, and the devices to pick each from.
Item {
    id: root

    // Polls the cards' jacks while a surface shows the devices.
    property bool active: false
    // AudioModel.unplugged() keys of the devices whose jack or port is empty.
    property var unpluggedKeys: []

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.isSink && !node.isStream) : []
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property var sources: Pipewire.nodes ? Pipewire.nodes.values.filter(node => node && node.audio && !node.isSink && !node.isStream) : []
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    // Every source muted: the mic-mute key and LED treat the mic as one.
    readonly property bool micMuted: sources.length > 0 && sources.every(node => node.audio.muted)
    readonly property string micIcon: micMuted ? "󰍭" : "󰍬"
    readonly property string icon: muted || volume <= 0 ? "󰖁" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"

    // Emitted by the volume and mic-mute keys, for the OSD.
    signal adjusted(bool mic)

    function label(node) {
        return node ? (node.nickname || node.description || node.name || "Unknown") : "";
    }

    // A device on an empty jack or port; it stays pickable.
    function isUnplugged(node) {
        return AudioModel.isUnplugged(unpluggedKeys, node);
    }

    function refreshJacks() {
        if (jacks.running)
            return;
        const cards = AudioModel.cards(sinks.concat(sources));
        if (cards.length === 0) {
            unpluggedKeys = [];
            return;
        }
        jacks.command = ["pw-dump"].concat(cards);
        jacks.running = true;
    }

    onActiveChanged: if (active)
        refreshJacks()

    function setVolume(value) {
        if (!sink || !sink.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function setMicVolume(value) {
        if (!source || !source.audio)
            return;
        source.audio.volume = Math.max(0, Math.min(1, value));
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

    // Selecting the current default would store it as the user's choice, ahead of an absent headset.
    function setDefault(node) {
        if (node && node !== sink)
            Pipewire.preferredDefaultAudioSink = node;
    }

    // As setDefault, for the input.
    function setDefaultSource(node) {
        if (node && node !== source)
            Pipewire.preferredDefaultAudioSource = node;
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

    // Quickshell exposes nodes, not cards: their routes' jack state comes from the cards' dump.
    Process {
        id: jacks
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.unpluggedKeys = AudioModel.unplugged(JSON.parse(text));
                } catch (error) {
                    root.unpluggedKeys = [];
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        onTriggered: root.refreshJacks()
    }
}
