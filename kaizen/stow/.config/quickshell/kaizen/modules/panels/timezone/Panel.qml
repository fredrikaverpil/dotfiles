import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/timezone/TimezoneModel.js" as Model

Ui.Panel {
    id: root

    required property var service

    readonly property var info: service.info

    cardWidth: 400
    keyNavigation: true
    // Held unmapped until a probe replaces the time left from the last open.
    visible: shown && service.fresh

    // date(1) and zdump run only while this is on screen.
    Binding {
        target: root.service
        property: "polling"
        value: root.shown
    }

    IpcHandler {
        target: "timezone"

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
        function set(zone: string): string {
            return root.service.setZone(zone) ? "ok" : "invalid";
        }
        function home(): void {
            root.service.resetZone();
        }
        function status(): string {
            return JSON.stringify({
                zone: root.info.zone,
                effective: view.mismatch === "" ? root.info.zone : view.mismatch,
                time: root.info.time,
                date: root.info.date,
                offset: root.info.offset,
                abbreviation: root.info.abbreviation,
                synchronized: root.info.synchronized,
                dst: Model.dstLabel(root.info.dst),
                next: Model.nextLabel(root.info.dst),
                error: root.service.lastError
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        // The launcher claims focus and closes this panel.
        onZoneRequested: root.shell.menu.open("settings.time.timezone")
    }
}
