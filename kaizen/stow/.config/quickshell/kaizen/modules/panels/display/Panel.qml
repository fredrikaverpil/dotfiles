import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    property var focusedMonitor: null

    readonly property var textScales: view.textScales

    cardWidth: view.cardWidth
    keyNavigation: view.keyNavigation

    function refresh() {
        if (!monitorState.running)
            monitorState.running = true;
        shell.brightness.refresh();
    }

    function setMonitorState(raw) {
        focusedMonitor = Ui.Compositor.focusedMonitor(raw);
    }

    onShownChanged: if (shown)
        refresh()

    IpcHandler {
        target: "display"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function status(): string {
            return JSON.stringify({
                monitor: root.focusedMonitor ? root.focusedMonitor.name : "",
                textScale: root.shell.textScale
            });
        }
    }

    Process {
        id: monitorState
        command: Ui.Compositor.outputs()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.setMonitorState(text)
        }
    }

    QtObject {
        id: outputState

        readonly property var focused: root.focusedMonitor
        readonly property var names: Quickshell.screens.map(screen => screen.name)
    }

    View {
        id: view
        shell: root.shell
        brightness: root.shell.brightness
        nightlight: root.shell.nightlight
        mirror: root.shell.mirror
        outputs: outputState
        onArrangeRequested: {
            root.close();
            Quickshell.execDetached(["wdisplays"]);
        }
        onWallpaperRequested: root.shell.background.open()
    }
}
