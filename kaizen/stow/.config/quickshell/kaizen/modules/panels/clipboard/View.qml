import QtQuick

import "../../../Ui" as Ui
import "../../services/clipboard/ClipboardModel.js" as Model
import "../../../Ui/Time.js" as Time

Column {
    id: root

    required property var shell
    // The clipboard service.
    required property var service

    // What the rows' times are read against; set on open.
    property date now: new Date()

    readonly property int cardWidth: 600
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    signal closeRequested

    // The newest entry is already on the clipboard, so focus starts on the one before it.
    function reset() {
        root.now = new Date();
        Qt.callLater(() => {
            const row = rows.itemAt(1) || rows.itemAt(0);
            if (row)
                row.forceActiveFocus();
        });
    }

    function pick(text) {
        root.service.copy(text);
        root.closeRequested();
    }

    // Removing rebuilds every row, so focus goes by position: the row that took the removed one's place.
    function drop(index) {
        root.service.remove(index);
        Qt.callLater(() => {
            const row = rows.itemAt(Math.min(index, rows.count - 1));
            if (row)
                row.forceActiveFocus(Qt.TabFocusReason);
        });
    }

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Clipboard"
        subtitle: {
            const count = root.service.history.length;
            if (count === 0)
                return "Nothing copied yet";
            return count + (count === 1 ? " entry" : " entries");
        }
    }

    Ui.PanelScroller {
        visible: root.service.history.length > 0
        shell: root.shell

        Ui.Section {
            shell: root.shell

            Column {
                width: root.width
                spacing: 4

                Repeater {
                    id: rows
                    model: root.service.history

                    delegate: EntryRow {}
                }
            }
        }
    }

    // A hidden footer's button never shows again, so the footer hides, not the button.
    Ui.PanelFooter {
        visible: root.service.history.length > 0
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
            onActivated: root.service.clear()
        }
    }

    // An entry: its first line, how many follow, when it was copied. Enter, Space or a click copies it.
    component EntryRow: Item {
        id: row

        required property var modelData
        required property int index
        readonly property int more: Model.moreLines(modelData.text)

        width: root.width
        implicitHeight: 28
        activeFocusOnTab: true

        Keys.onReturnPressed: root.pick(row.modelData.text)
        Keys.onEnterPressed: root.pick(row.modelData.text)
        Keys.onSpacePressed: root.pick(row.modelData.text)
        Keys.onPressed: function (event) {
            if (event.key !== Qt.Key_Backspace)
                return;
            root.drop(row.index);
            event.accepted = true;
        }

        // The fill reaches into the card's padding, so the text aligns with the rule.
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            radius: 4
            color: row.activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
        }

        Text {
            anchors.left: parent.left
            anchors.right: more.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            textFormat: Text.PlainText
            text: Model.preview(row.modelData.text)
        }

        Text {
            id: more
            anchors.right: time.left
            anchors.rightMargin: row.more > 0 ? 16 : 0
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: row.more > 0 ? "+" + row.more + (row.more === 1 ? " line" : " lines") : ""
        }

        Text {
            id: time
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: Time.stamp(row.modelData.at, root.now)
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            hoverEnabled: true
            onClicked: root.pick(row.modelData.text)
        }
    }
}
