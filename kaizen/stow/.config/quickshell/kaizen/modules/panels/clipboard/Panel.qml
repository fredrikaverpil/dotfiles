import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: 600
    keyNavigation: true

    onShownChanged: if (shown)
        view.reset()

    IpcHandler {
        target: "clipboard"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function clear(): void {
            root.service.clear();
        }
        function status(): string {
            return JSON.stringify({
                entries: root.service.history.length
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onCloseRequested: root.close()
    }
}
