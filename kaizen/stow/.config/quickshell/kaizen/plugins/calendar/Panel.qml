import QtQuick
import Quickshell
import Quickshell.Io

import qs.Ui as Ui

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    keyNavigation: view.keyNavigation

    onShownChanged: if (shown)
        service.refresh()

    function openEvent(event) {
        Quickshell.execDetached(["dcal", "ipc", "ui.openEvent", "uid=" + event.uid, "start=" + event.start]);
        root.close();
    }

    function openApp() {
        Quickshell.execDetached(["dcal", "show"]);
        root.close();
    }

    function join(event) {
        Quickshell.execDetached(["xdg-open", event.meetingUrl]);
        root.close();
    }

    IpcHandler {
        target: "calendar"

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
        function status(): string {
            return JSON.stringify({
                failed: root.service.failed,
                days: root.service.days.length,
                events: root.service.days.reduce((count, day) => count + day.events.length, 0)
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onOpenRequested: event => root.openEvent(event)
        onJoinRequested: event => root.join(event)
        onAppRequested: root.openApp()
    }
}
