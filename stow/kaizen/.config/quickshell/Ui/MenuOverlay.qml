import QtQuick

import "MenuCardModel.js" as Model

// An application's palette, drawn over its window's content: a MenuCard that
// drills in place under a breadcrumb. The host binds tree, so the rows follow
// its state, and runs the rows it is handed.
Item {
    id: overlay

    required property var shell
    // Card rows plus key; a submenu's rows are its children.
    property var tree: []
    // The breadcrumb's first part.
    property string title: ""
    // Takes the keyboard on close when the item that had it is gone or hidden.
    property Item fallback: null
    property var openerKeys: []
    // The keys of the submenus drilled into.
    property var path: []
    // Where focus was when the menu opened.
    property Item before: null
    readonly property var level: Model.level(tree, path)

    signal runRequested(var row)

    visible: false

    // A menu opening over another keeps the focus saved by the first.
    function open(keys) {
        if (!visible)
            before = overlay.Window.window?.activeFocusItem ?? null;
        openerKeys = keys || [];
        path = [];
        card.clear();
        visible = true;
        card.focusSearch();
        Qt.callLater(card.selectFirst);
    }

    function toggle(keys) {
        if (visible)
            close();
        else
            open(keys);
    }

    // Never leaves focus on a hidden item: a hidden field swallows letters.
    function close() {
        visible = false;
        path = [];
        const target = before && before.visible ? before : fallback;
        before = null;
        if (target)
            target.forceActiveFocus();
    }

    function drill(keys) {
        path = keys;
        card.clear();
        Qt.callLater(card.selectFirst);
    }

    MouseArea {
        anchors.fill: parent
        onPressed: overlay.close()
    }

    Rectangle {
        id: frame

        x: Math.round((overlay.width - width) / 2)
        // Fixed, so a narrowing query never moves it.
        y: Math.round(overlay.height / 6)
        width: Math.min(520, overlay.width - 32)
        height: Math.min(card.y + card.implicitHeight + 8, overlay.height - y - 16)
        radius: 8
        color: overlay.shell.palette.bg
        border.color: overlay.shell.palette.dim
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: breadcrumb
            x: 12
            y: 8
            width: parent.width - 24
            elide: Text.ElideRight
            color: overlay.shell.palette.off
            font.family: Fonts.mono
            font.pixelSize: 13
            text: [overlay.title].concat(overlay.level.names).join(" › ")
        }

        MenuCard {
            id: card
            x: 4
            y: breadcrumb.y + breadcrumb.height + 4
            width: parent.width - 8
            height: parent.height - y - 4
            shell: overlay.shell
            rows: overlay.visible ? Model.search(overlay.level.rows, card.query) : []
            // From level alone: it can lag a change of path.
            placeholder: overlay.level.names.length ? "Filter " + overlay.level.names[overlay.level.names.length - 1].toLowerCase() + "…" : "Search…"
            openerKeys: overlay.openerKeys
            fontSize: 16
            rowHeight: 36
            // The frame fixes the width.
            maxWidth: 0

            onOpenRequested: row => {
                overlay.drill(overlay.path.concat(row.trail || [], [row.key]));
                card.settle();
            }
            // Focus returns before the row runs, so a row may move it.
            onRunRequested: row => {
                overlay.close();
                overlay.runRequested(row);
            }
            onBackRequested: {
                if (overlay.path.length)
                    overlay.drill(overlay.path.slice(0, -1));
                else
                    overlay.close();
            }
            onCloseRequested: overlay.close()
        }
    }
}
