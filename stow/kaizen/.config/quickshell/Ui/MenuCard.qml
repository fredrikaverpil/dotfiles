import QtQuick
import Quickshell

import "MenuCardModel.js" as Model

// A menu's search row and rows, for any window to host. The host supplies the
// rows for query and decides what opening a submenu does: cascade or drill in.
Item {
    id: card

    required property var shell
    // Shaped like QsMenuEntry, plus glyph, image, detail and keys.
    property var rows: []
    property string placeholder: "Filter…"
    // The keys that opened the menu, when a bind did.
    property var openerKeys: []
    property real fontSize: 14
    property int rowHeight: 28
    // Measuring stops at this width; a level can hold thousands of rows.
    property real maxWidth: Infinity
    property int current: -1

    readonly property alias query: input.text
    readonly property var shownRows: query.length > 0 ? rows.filter(row => !row.isSeparator) : rows
    readonly property int rowsHeight: shownRows.reduce((sum, row) => sum + (row.isSeparator ? 9 : rowHeight), 0) + Math.max(0, shownRows.length - 1) * list.spacing

    signal openRequested(var row, bool selectFirst)
    signal runRequested(var row)
    signal backRequested
    signal closeRequested
    signal hovered(int index)

    implicitWidth: widest
    implicitHeight: list.y + rowsHeight

    function focusSearch() {
        input.forceActiveFocus();
    }

    // Set while there is no row to select yet: tray menus fill after opening.
    property bool firstPending: false

    function selectFirst() {
        current = Model.step(shownRows, -1, 1);
        firstPending = current < 0;
    }

    function move(steps) {
        current = Model.step(shownRows, current, steps);
    }

    function activate(selectFirst) {
        const row = shownRows[current];
        if (!row || row.isSeparator || !row.enabled)
            return;
        if (row.hasChildren)
            openRequested(row, selectFirst);
        else
            runRequested(row);
    }

    // Top of row index, in window coordinates.
    function rowTop(index) {
        const row = list.itemAtIndex(index);
        return (row || card).mapToItem(null, 0, 0).y;
    }

    // Blocks a repeating Enter from running a submenu's first row.
    property bool settling: false

    function settle() {
        settling = true;
        settleTimer.restart();
    }

    Timer {
        id: settleTimer
        interval: 250
        onTriggered: card.settling = false
    }

    function onKey(event) {
        const row = shownRows[current];
        const control = event.modifiers & Qt.ControlModifier;
        const empty = input.text.length === 0;
        if (event.key === Qt.Key_Escape)
            closeRequested();
        else if (event.key === Qt.Key_Down || control && event.key === Qt.Key_N)
            move(1);
        else if (event.key === Qt.Key_Up || control && event.key === Qt.Key_P)
            move(-1);
        else if (event.key === Qt.Key_PageDown)
            move(10);
        else if (event.key === Qt.Key_PageUp)
            move(-10);
        else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            // The menu keeps the keyboard until it closes.
        } else if (event.key === Qt.Key_Right && row && row.hasChildren && row.enabled)
            openRequested(row, true);
        else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) && empty)
            backRequested();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (!settling)
                activate(true);
        } else
            return;
        event.accepted = true;
    }

    // Rows rebuilt or scrolled under a resting pointer report hover too; act on real motion only.
    property point pointer: Qt.point(-1, -1)

    function moved(point) {
        if (point.x === pointer.x && point.y === pointer.y)
            return false;
        const first = pointer.x < 0;
        pointer = point;
        return !first;
    }

    // Widest row seen, so a query never narrows the card.
    property real widest: 0

    function rowWidth(row) {
        if (row.isSeparator)
            return 0;
        const keys = row.keys || [];
        return 16 + fontSize + 12 + metrics.advanceWidth(row.text || "") + (row.detail ? 8 + metrics.advanceWidth(row.detail) : 0) + (keys.length ? 8 + capsWidth(keys) : 0) + (row.hasChildren ? 8 + metrics.advanceWidth("›") : 0);
    }

    function capsWidth(keys) {
        return keys.reduce((sum, key) => sum + keyMetrics.advanceWidth(key) + 13, -3);
    }

    onShownRowsChanged: {
        let widest = Math.max(card.widest, metrics.advanceWidth(placeholder) + (openerKeys.length ? 8 + capsWidth(openerKeys) : 0) + 16);
        for (let i = 0; i < shownRows.length && widest < maxWidth; i++)
            widest = Math.max(widest, rowWidth(shownRows[i]));
        card.widest = widest;
        if (firstPending)
            selectFirst();
    }

    onCurrentChanged: if (current >= 0)
        list.positionViewAtIndex(current, ListView.Contain)

    FontMetrics {
        id: metrics
        font.family: Fonts.mono
        font.pixelSize: card.fontSize
    }

    FontMetrics {
        id: keyMetrics
        font.family: Fonts.mono
        font.pixelSize: card.fontSize - 2
    }

    Item {
        id: search
        width: parent.width
        height: card.rowHeight

        TextInput {
            id: input
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: opener.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            focus: true
            color: card.shell.palette.fg
            font.family: Fonts.mono
            font.pixelSize: card.fontSize

            // ListView settles its own state after this handler runs.
            onTextChanged: Qt.callLater(card.selectFirst)
            Keys.onPressed: event => card.onKey(event)

            Text {
                anchors.fill: parent
                visible: input.text.length === 0
                color: card.shell.palette.off
                font: input.font
                text: card.placeholder
                elide: Text.ElideRight
            }
        }

        Keycaps {
            id: opener
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            shell: card.shell
            keys: card.openerKeys
            fontSize: card.fontSize - 2
        }

        MouseArea {
            anchors.fill: parent
            onClicked: input.forceActiveFocus()
        }
    }

    Rectangle {
        id: rule
        y: search.height
        width: parent.width
        height: 1
        color: card.shell.palette.dim
    }

    ListView {
        id: list
        y: rule.y + rule.height + 4
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: 2
        model: card.shownRows
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index
            readonly property bool usable: !modelData.isSeparator && modelData.enabled

            width: list.width
            height: modelData.isSeparator ? 9 : card.rowHeight
            radius: 4
            color: index === card.current ? card.shell.palette.sel : "transparent"

            Rectangle {
                visible: row.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16
                x: 8
                height: 1
                color: card.shell.palette.dim
            }

            Item {
                visible: !row.modelData.isSeparator
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Item {
                    id: icon
                    width: card.fontSize + 2
                    height: parent.height

                    Image {
                        id: image
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.width
                        source: row.modelData.image || ""
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize.width: width * Screen.devicePixelRatio
                        sourceSize.height: height * Screen.devicePixelRatio
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !image.visible
                        color: row.usable ? card.shell.palette.fg : card.shell.palette.off
                        font.family: Fonts.mono
                        font.pixelSize: card.fontSize
                        text: row.modelData.buttonType === QsMenuButtonType.CheckBox ? (row.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱") : row.modelData.buttonType === QsMenuButtonType.RadioButton ? (row.modelData.checkState === Qt.Checked ? "󰐾" : "󰐽") : row.modelData.glyph ?? ""
                    }
                }

                Text {
                    id: chevron
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.hasChildren === true
                    width: visible ? implicitWidth : 0
                    color: row.usable ? card.shell.palette.fg : card.shell.palette.off
                    font.family: Fonts.mono
                    font.pixelSize: card.fontSize
                    text: "›"
                }

                Keycaps {
                    id: keys
                    anchors.right: chevron.left
                    anchors.rightMargin: chevron.visible ? 8 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    shell: card.shell
                    keys: row.modelData.keys || []
                    fontSize: card.fontSize - 2
                }

                Text {
                    id: label
                    anchors.left: icon.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, keys.x - x - (keys.width > 0 ? 8 : 0))
                    color: row.usable ? card.shell.palette.fg : card.shell.palette.off
                    font.family: Fonts.mono
                    font.pixelSize: card.fontSize
                    text: row.modelData.text || ""
                    elide: Text.ElideRight
                }

                Text {
                    anchors.left: label.right
                    anchors.leftMargin: 8
                    anchors.right: keys.left
                    anchors.rightMargin: keys.width > 0 ? 8 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    color: card.shell.palette.off
                    font.family: Fonts.mono
                    font.pixelSize: card.fontSize
                    text: row.modelData.detail || ""
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !row.modelData.isSeparator
                hoverEnabled: true
                onPositionChanged: function (mouse) {
                    if (!card.moved(mapToItem(null, mouse.x, mouse.y)))
                        return;
                    if (row.usable)
                        card.current = row.index;
                    card.hovered(row.index);
                }
                onClicked: {
                    card.current = row.index;
                    card.activate(false);
                }
            }
        }
    }
}
