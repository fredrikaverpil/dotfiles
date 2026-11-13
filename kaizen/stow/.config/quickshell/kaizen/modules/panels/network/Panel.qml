import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    keyNavigation: view.keyNavigation

    Binding {
        target: root.service
        property: "active"
        value: root.shown
    }

    IpcHandler {
        target: "network"

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
            Quickshell.execDetached(["nm-connection-editor"]);
        }
    }
}
