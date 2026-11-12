import QtQuick

import "../../../Ui" as Ui
import "../../services/doctor/DoctorModel.js" as Model

Column {
    id: root

    required property var shell
    // The doctor service, or the gallery's stand-in.
    required property var service

    // What was last copied, shown until the panel closes.
    property string copied: ""

    readonly property int cardWidth: 720
    readonly property int cardHeight: 520
    readonly property bool keyNavigation: true

    // The report's first line counts the findings.
    readonly property string statusText: {
        if (service.checked === 0)
            return service.running ? "Checking…" : "";
        return "Checked " + Model.clock(service.checked) + (service.running ? " · checking…" : "");
    }

    function reset() {
        Qt.callLater(() => document.forceActiveFocus());
    }

    function copyAll() {
        if (root.service.copyAll())
            root.copied = "the report";
    }

    // Moves the cursor to pos, extending the selection with Shift.
    function moveCursor(pos, event) {
        if (event.modifiers & Qt.ShiftModifier)
            document.moveCursorSelection(pos, TextEdit.SelectCharacters);
        else
            document.cursorPosition = pos;
    }

    function follow() {
        const rect = document.cursorRectangle;
        if (rect.y < scroller.contentY)
            scroller.contentY = Math.max(0, rect.y);
        else if (rect.y + rect.height > scroller.contentY + scroller.height)
            scroller.contentY = rect.y + rect.height - scroller.height;
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    spacing: 8

    Column {
        id: header
        width: parent.width
        spacing: 10

        Text {
            width: parent.width
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 18
            text: "Doctor"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.shell.palette.dim
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.WordWrap
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: root.statusText
        }

        Text {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.WrapAnywhere
            color: root.shell.palette.rose
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
            text: root.service.failure
        }
    }

    // A read-only document: arrows, PageUp/PageDown and Home/End stay in it;
    // Tab and hjkl step focus as elsewhere in panels.
    Rectangle {
        width: parent.width
        height: parent.height - header.height - footer.height - 2 * parent.spacing
        radius: 4
        color: "transparent"
        border.color: document.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1

        Flickable {
            id: scroller
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: width
            contentHeight: document.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // What the document leaves at its edges.
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right)
                    event.accepted = true;
            }

            TextEdit {
                id: document
                width: scroller.width
                readOnly: true
                selectByKeyboard: true
                selectByMouse: true
                activeFocusOnTab: true
                cursorVisible: activeFocus
                textFormat: TextEdit.RichText
                wrapMode: TextEdit.Wrap
                color: root.shell.palette.fg
                selectionColor: root.shell.palette.sel
                selectedTextColor: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: Model.html(root.service.text, root.shell.palette)

                onCursorRectangleChanged: root.follow()

                Keys.onPressed: function (event) {
                    const rect = cursorRectangle;
                    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                        const y = rect.y + (event.key === Qt.Key_PageUp ? -1 : 1) * scroller.height;
                        root.moveCursor(positionAt(rect.x, Math.max(0, Math.min(height - 1, y))), event);
                    } else if (event.key === Qt.Key_Home) {
                        root.moveCursor(0, event);
                    } else if (event.key === Qt.Key_End) {
                        root.moveCursor(length, event);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }
    }

    Column {
        id: footer
        width: parent.width
        spacing: 10

        Text {
            width: parent.width
            visible: root.copied !== ""
            color: root.shell.palette.leaf
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
            text: "Copied " + root.copied
        }

        Row {
            spacing: 8

            Action {
                label: "󰑐 Refresh"
                available: !root.service.running
                onActivated: root.service.refresh()
            }

            Action {
                label: "󰆏 Copy all"
                available: root.service.text !== ""
                onActivated: root.copyAll()
            }
        }
    }

    component Action: Rectangle {
        id: action

        property string label
        property bool available: true

        signal activated

        width: 140
        height: 28
        radius: 4
        color: activeFocus ? root.shell.palette.sel : "transparent"
        border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        opacity: available ? 1 : 0.45
        activeFocusOnTab: true

        Keys.onReturnPressed: if (available)
            activated()
        Keys.onEnterPressed: if (available)
            activated()
        Keys.onSpacePressed: if (available)
            activated()

        Text {
            anchors.centerIn: parent
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
            text: action.label
        }

        MouseArea {
            anchors.fill: parent
            enabled: action.available
            onClicked: action.activated()
        }
    }
}
