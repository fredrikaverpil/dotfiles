import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    keyNavigation: view.keyNavigation

    IpcHandler {
        target: "bluetooth"

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
            return root.service.status();
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onSettingsRequested: {
            root.close();
            Quickshell.execDetached(["xdg-terminal-exec", "bluetui"]);
        }
    }
}
