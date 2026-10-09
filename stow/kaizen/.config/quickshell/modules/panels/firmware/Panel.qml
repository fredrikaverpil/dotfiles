import QtQuick
import QtQuick.Window
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/firmware/FirmwareModel.js" as Model

Ui.Panel {
    id: root

    required property var service

    // The update command last copied, shown until the panel closes.
    property string copied: ""

    cardWidth: 560
    cardHeight: 460
    keyNavigation: true

    readonly property string statusText: {
        if (service.backends.length === 0)
            return "No firmware backend on this host";
        if (service.checking && service.lastChecked === 0)
            return "Checking…";
        const count = service.pending.length;
        const checked = service.lastChecked === 0 ? "" : " · checked " + Qt.formatDateTime(new Date(service.lastChecked), "HH:mm");
        if (count === 0 && service.errors.length > 0)
            return "Check failed" + checked;
        return (count === 0 ? "Up to date" : count + " pending") + checked;
    }

    function copy(update) {
        if (root.service.copyCommand(update.id))
            root.copied = update.command;
    }

    function openPage(update) {
        if (root.service.openPage(update.id))
            root.close();
    }

    onShownChanged: {
        if (shown)
            service.refresh();
        else
            copied = "";
    }

    readonly property var focusedItem: scroller.Window.activeFocusItem
    // Map to content coordinates: Flickable coordinates are relative to its viewport.
    onFocusedItemChanged: {
        const item = focusedItem;
        if (!item || !shown)
            return;
        const top = item.mapToItem(content, 0, 0).y;
        if (!isFinite(top))
            return;
        if (top < scroller.contentY)
            scroller.contentY = Math.max(0, top);
        else if (top + item.height > scroller.contentY + scroller.height)
            scroller.contentY = top + item.height - scroller.height;
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

    Flickable {
        id: scroller
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: scroller.width
            spacing: 10

            Text {
                width: parent.width
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 18
                text: "Firmware"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.shell.palette.dim
            }

            Text {
                width: parent.width
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: root.statusText
            }

            Repeater {
                model: root.service.errors

                delegate: Text {
                    required property var modelData

                    width: content.width
                    wrapMode: Text.WordWrap
                    color: root.shell.palette.rose
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: "󰀦 " + modelData.backend + ": " + modelData.error
                }
            }

            Repeater {
                model: root.service.updates

                delegate: UpdateRow {
                    required property var modelData
                    update: modelData
                }
            }

            Text {
                width: parent.width
                visible: root.copied !== ""
                wrapMode: Text.WrapAnywhere
                color: root.shell.palette.leaf
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: "Copied: " + root.copied
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.shell.palette.dim
            }

            Rectangle {
                id: checkButton

                readonly property bool available: root.service.backends.length > 0 && !root.service.checking

                width: 140
                height: 28
                radius: 4
                color: activeFocus ? root.shell.palette.sel : "transparent"
                border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
                border.width: 1
                opacity: available ? 1 : 0.45
                activeFocusOnTab: true

                Keys.onReturnPressed: if (available)
                    root.service.refresh()
                Keys.onEnterPressed: if (available)
                    root.service.refresh()
                Keys.onSpacePressed: if (available)
                    root.service.refresh()

                Text {
                    anchors.centerIn: parent
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: root.service.checking ? "Checking…" : "󰑐 Check now"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: checkButton.available
                    onClicked: root.service.refresh()
                }
            }
        }
    }

    // Enter, Space or a click copies the update command; O opens the release
    // page; focus shows the release notes and page.
    component UpdateRow: Rectangle {
        id: row

        required property var update
        readonly property bool counted: Model.counts(update, root.service.secureBoot)

        width: content.width
        height: rowColumn.implicitHeight + 16
        radius: 4
        color: activeFocus ? root.shell.palette.sel : "transparent"
        border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: root.copy(row.update)
        Keys.onEnterPressed: root.copy(row.update)
        Keys.onSpacePressed: root.copy(row.update)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_O && event.modifiers === Qt.NoModifier) {
                root.openPage(row.update);
                event.accepted = true;
            }
        }

        Column {
            id: rowColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 4

            Row {
                width: parent.width
                spacing: 8

                Text {
                    width: parent.width - urgency.implicitWidth - parent.spacing
                    elide: Text.ElideRight
                    color: row.counted ? root.shell.palette.fg : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: row.update.name + (row.update.vendor === "" ? "" : " · " + row.update.vendor)
                }

                Text {
                    id: urgency
                    color: row.counted ? root.shell.palette[Model.urgencyRole(row.update.urgency)] : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: row.update.urgency
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: Model.detail(row.update, root.service.secureBoot)
            }

            Text {
                width: parent.width
                visible: row.activeFocus && row.update.notes !== ""
                wrapMode: Text.WordWrap
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: row.update.notes
            }

            Row {
                width: parent.width
                visible: row.activeFocus && row.update.url !== ""
                spacing: 8

                Text {
                    width: parent.width - pageKey.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    color: root.shell.palette.water
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    font.underline: true
                    text: row.update.url

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPage(row.update)
                    }
                }

                Ui.Keycaps {
                    id: pageKey
                    shell: root.shell
                    keys: ["O"]
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                row.forceActiveFocus();
                root.copy(row.update);
            }
        }
    }
}
