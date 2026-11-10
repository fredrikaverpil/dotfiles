import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui

Ui.Panel {
    id: root

    required property var service

    readonly property string icon: service.icon

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    cardPadding: view.cardPadding
    keyNavigation: view.keyNavigation

    onShownChanged: if (shown)
        view.reset()

    Binding {
        target: root.service
        property: "active"
        value: root.shown
    }

    IpcHandler {
        target: "media"

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
            return root.service.statusJson();
        }
        function playPause(): string {
            return root.service.runAction("playPause") ? "ok" : "unhandled";
        }
        function previous(): string {
            return root.service.runAction("previous") ? "ok" : "unhandled";
        }
        function next(): string {
            return root.service.runAction("next") ? "ok" : "unhandled";
        }
        function play(): string {
            return root.service.runAction("play") ? "ok" : "unhandled";
        }
        function pause(): string {
            return root.service.runAction("pause") ? "ok" : "unhandled";
        }
        function select(key: string): string {
            return root.service.selectPlayer(key) ? "ok" : "unknown";
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
    }
}
