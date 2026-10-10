import QtQuick
import QtQuick.Window
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/log/LogModel.js" as Model

Ui.Panel {
    id: root

    required property var service

    // What was last copied, shown until the panel closes.
    property string copied: ""
    // Newest first; empty while hidden, so new entries build no rows.
    readonly property var rows: shown ? service.entries.slice().reverse() : []

    cardWidth: 720
    cardHeight: 520
    keyNavigation: true

    readonly property string statusText: {
        const count = service.count;
        if (count === 0)
            return "Nothing logged this boot";
        const warnings = count - service.errors;
        const parts = [];
        if (service.errors > 0)
            parts.push(service.errors + (service.errors === 1 ? " error" : " errors"));
        if (warnings > 0)
            parts.push(warnings + (warnings === 1 ? " warning" : " warnings"));
        const more = count > service.entries.length ? " · latest " + service.entries.length + " shown, kaizen-log lists all" : "";
        return parts.join(", ") + " this boot" + more;
    }

    function copy(entry) {
        const text = Model.line(entry);
        root.service.copy(text);
        root.copied = text;
    }

    function copyAll() {
        if (root.service.copyAll())
            root.copied = root.service.entries.length + " lines";
    }

    onShownChanged: {
        if (!shown)
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
        target: "log"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function copy(): string {
            return root.service.copyAll() ? "ok" : "empty";
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
                text: "Log"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.shell.palette.dim
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: root.statusText
            }

            Repeater {
                model: root.rows

                delegate: EntryRow {
                    required property var modelData
                    entry: modelData
                }
            }

            Text {
                width: parent.width
                visible: root.copied !== ""
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
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
                id: copyButton

                readonly property bool available: root.service.entries.length > 0

                width: 140
                height: 28
                radius: 4
                color: activeFocus ? root.shell.palette.sel : "transparent"
                border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
                border.width: 1
                opacity: available ? 1 : 0.45
                activeFocusOnTab: true

                Keys.onReturnPressed: root.copyAll()
                Keys.onEnterPressed: root.copyAll()
                Keys.onSpacePressed: root.copyAll()

                Text {
                    anchors.centerIn: parent
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: "󰆏 Copy all"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: copyButton.available
                    onClicked: root.copyAll()
                }
            }
        }
    }

    // Enter, Space or a click copies the entry's line; focus shows it whole.
    component EntryRow: Rectangle {
        id: row

        required property var entry

        width: content.width
        height: rowColumn.implicitHeight + 16
        radius: 4
        color: activeFocus ? root.shell.palette.sel : "transparent"
        border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: root.copy(row.entry)
        Keys.onEnterPressed: root.copy(row.entry)
        Keys.onSpacePressed: root.copy(row.entry)

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
                    width: parent.width - level.implicitWidth - parent.spacing
                    elide: Text.ElideRight
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: Model.clock(row.entry.time) + " · " + row.entry.unit
                }

                Text {
                    id: level
                    color: root.shell.palette[Model.role(row.entry.level)]
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: row.entry.level
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WrapAnywhere
                maximumLineCount: row.activeFocus ? 1000 : 2
                elide: Text.ElideRight
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: row.entry.message
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                row.forceActiveFocus();
                root.copy(row.entry);
            }
        }
    }
}
