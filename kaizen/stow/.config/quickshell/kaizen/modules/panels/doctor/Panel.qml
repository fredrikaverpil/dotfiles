import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    keyNavigation: view.keyNavigation

    onShownChanged: {
        if (shown) {
            service.refresh();
            view.reset();
        } else {
            view.copied = "";
        }
    }

    IpcHandler {
        target: "doctor"

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
        function copy(): string {
            return root.service.copyAll() ? "ok" : "empty";
        }
        function status(): string {
            return root.service.status();
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
    }
}
