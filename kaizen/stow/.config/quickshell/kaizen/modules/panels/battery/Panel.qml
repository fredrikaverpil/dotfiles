import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    keyNavigation: view.keyNavigation

    onShownChanged: if (shown)
        service.refresh()

    IpcHandler {
        target: "battery"

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
        function setProfile(name: string): string {
            return root.service.setProfile(name) ? name : "unavailable";
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
    }
}
