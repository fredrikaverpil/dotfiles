import QtQuick
import Quickshell.Services.Pipewire

// umbriel reports no screencast state; its portal's PipeWire node lives as long
// as an app's screen share, paused ones included.
QtObject {
    readonly property bool sharing: Pipewire.nodes.values.some(node => node.name === "umbriel-screen-capture")
}
