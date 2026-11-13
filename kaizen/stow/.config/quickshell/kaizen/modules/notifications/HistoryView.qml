import QtQuick

import "../../Ui" as Ui
import "components"

Column {
    id: root

    required property var shell
    // The notification service.
    required property var service

    // The cards animate only while the panel is open.
    property bool shown: true
    readonly property int count: service.historyRows.length

    readonly property int cardWidth: 600
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    signal actionRequested(var row, var action)

    function reset() {
        Qt.callLater(() => {
            const row = rows.itemAt(0);
            if (row)
                row.forceActiveFocus();
        });
    }

    // Removing rebuilds every card, so focus goes by position: the card that took the removed one's
    // place, or the DnD button once none is left.
    function drop(index) {
        root.service.removeHistory(index);
        Qt.callLater(() => {
            const row = rows.itemAt(Math.min(index, rows.count - 1));
            if (row)
                row.forceActiveFocus(Qt.TabFocusReason);
            else
                dnd.forceActiveFocus(Qt.TabFocusReason);
        });
    }

    width: parent ? parent.width : 0
    spacing: 24

    // DnD's button sits where a key value would: it is the panel's key state.
    Item {
        width: parent.width
        implicitHeight: Math.max(header.implicitHeight, dnd.height)

        Ui.PanelHeader {
            id: header
            width: parent.width - dnd.width - 8
            shell: root.shell
            title: "Notifications"
            subtitle: {
                if (!root.service.doNotDisturb)
                    return root.count === 0 ? "Showing notifications" : "Showing notifications · " + root.count + " held back";
                return "Paused · " + (root.count === 0 ? "nothing" : root.count) + " held back";
            }
        }

        Ui.PanelButton {
            id: dnd
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            // As wide for either label, so the button keeps its place.
            width: dndMetrics.advanceWidth + 24
            shell: root.shell
            label: root.service.doNotDisturb ? "Resume" : "Pause"
            onActivated: root.service.setDoNotDisturb(!root.service.doNotDisturb)
        }

        TextMetrics {
            id: dndMetrics
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "Resume"
        }
    }

    Ui.PanelScroller {
        visible: root.count > 0
        shell: root.shell

        Ui.Section {
            shell: root.shell

            Column {
                width: root.width
                spacing: 8

                Repeater {
                    id: rows
                    model: root.service.historyRows

                    // The toast's own card, its tint, badge and animation included (style.md › Panels).
                    delegate: NotificationCard {
                        required property var modelData
                        required property int index

                        width: root.width
                        palette: root.shell.palette
                        row: modelData
                        toast: false
                        animated: root.shown
                        selectable: true
                        onCloseRequested: root.drop(index)
                        onActionRequested: action => root.actionRequested(modelData, action)
                    }
                }
            }
        }
    }

    // A hidden footer's button never shows again, so the footer hides, not the button.
    Ui.PanelFooter {
        visible: root.count > 0
        shell: root.shell
        entries: [
            {
                keys: ["Backspace"],
                label: "remove"
            }
        ]

        Ui.PanelButton {
            shell: root.shell
            label: "Clear history"
            onActivated: root.service.clearHistory()
        }
    }
}
