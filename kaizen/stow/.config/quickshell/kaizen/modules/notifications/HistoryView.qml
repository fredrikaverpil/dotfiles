import QtQuick

import "../../Ui" as Ui
import "components"

Column {
    id: root

    required property var shell
    // The notification service.
    required property var service

    // The cards animate only while the panel is open.
    required property bool shown
    readonly property int count: service.historyRows.length
    // What the cards' times are read against; set on open.
    property date now: new Date()

    signal actionRequested(var row, var action)

    function reset() {
        root.now = new Date();
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

    Ui.PanelHeader {
        shell: root.shell
        title: "Notifications"
        subtitle: {
            if (!root.service.doNotDisturb)
                return root.count === 0 ? "Showing notifications" : "Showing notifications · " + root.count + " held back";
            return "Paused · " + (root.count === 0 ? "nothing" : root.count) + " held back";
        }

        // DnD's button sits where a key value would: it is the panel's key state.
        Ui.PanelButton {
            id: dnd
            widest: "Resume"
            shell: root.shell
            label: root.service.doNotDisturb ? "Resume" : "Pause"
            onActivated: root.service.setDoNotDisturb(!root.service.doNotDisturb)
        }
    }

    Ui.PanelScroller {
        visible: root.count > 0
        shell: root.shell
        bleed: 64

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
                        now: root.now
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
