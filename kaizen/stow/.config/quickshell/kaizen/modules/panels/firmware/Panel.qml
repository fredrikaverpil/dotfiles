import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    cardPadding: view.cardPadding
    keyNavigation: view.keyNavigation

    onShownChanged: {
        if (shown)
            service.refresh();
        else
            view.copied = "";
    }

    IpcHandler {
        target: "firmware"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function refresh(): void {
            root.service.refresh();
        }
        function copy(id: string): string {
            return root.service.copyCommand(id) ? "ok" : "unknown";
        }
        function openPage(id: string): string {
            return root.service.openPage(id) ? "ok" : "unknown";
        }
        function status(): string {
            return root.service.status();
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onCloseRequested: root.close()
    }
}
