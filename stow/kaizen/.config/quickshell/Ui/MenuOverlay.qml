import QtQuick

import "MenuCardModel.js" as Model

// An application's menus, drawn over its window's content. The palette is a
// MenuCard that drills in place under a breadcrumb. Its rows come from the
// scopes around the focus: the item that had it and its parents, each
// declaring `function menuScope()` that returns { title, rows }, card rows plus
// key with a submenu's rows as its children. A context menu (`popup()`) hangs
// from the pointer or a control and cascades its submenus. A row with `adds`
// adds what was typed (MenuCardModel.search). The host runs the rows it is
// handed.
Item {
    id: overlay

    required property var shell
    // The breadcrumb's first part.
    property string title: ""
    // Takes the keyboard on close when the item that had it is gone or hidden.
    property Item fallback: null
    property var openerKeys: []
    // The keys of the submenus drilled into.
    property var path: []
    // Where focus was when the menu opened.
    property Item before: null
    // The items with a scope, from there up. A reload can destroy one while open.
    property var chain: []
    // Returns the context menu's rows; null while the palette is open.
    property var source: null
    readonly property bool context: source !== null
    readonly property var tree: context ? ({
            rows: source(),
            names: []
        }) : Model.scoped(chain.filter(item => item && typeof item.menuScope === "function").map(item => item.menuScope()))
    readonly property var level: Model.level(tree.rows, path)
    // One context menu card per level: { path, anchor, selectFirst }. The
    // root's anchor is the pointer or a control, a submenu's its row.
    property var stack: []

    signal runRequested(var row)

    visible: false

    // A menu opening over another keeps the focus saved by the first.
    function open(keys) {
        if (!visible)
            before = overlay.Window.window?.activeFocusItem ?? null;
        if (!visible || context) {
            reset();
            chain = scopes(before ?? fallback);
        }
        openerKeys = keys || [];
        path = [];
        card.clear();
        visible = true;
        card.focusSearch();
        Qt.callLater(card.selectFirst);
    }

    // Opens a context menu hanging from `at`, a rect in the overlay's
    // coordinates. rows returns its tree, so a binding calling it stays live.
    function popup(rows, at, selectFirst) {
        if (!visible)
            before = overlay.Window.window?.activeFocusItem ?? null;
        reset();
        source = rows;
        visible = true;
        push([], at, selectFirst);
    }

    function scopes(item) {
        const found = [];
        for (let each = item; each; each = each.parent)
            if (typeof each.menuScope === "function")
                found.push(each);
        return found;
    }

    // Closes the palette; replaces a context menu with it.
    function toggle(keys) {
        if (visible && !context)
            close();
        else
            open(keys);
    }

    // Never leaves focus on a hidden item: a hidden field swallows letters.
    function close() {
        visible = false;
        reset();
        const target = before && before.visible ? before : fallback;
        before = null;
        if (target)
            target.forceActiveFocus();
    }

    function reset() {
        hoverTimer.stop();
        truncate(0);
        source = null;
        path = [];
        chain = [];
    }

    // Focus returns before the row runs, so a row may move it.
    function run(row) {
        close();
        runRequested(row);
    }

    function drill(keys) {
        path = keys;
        card.clear();
        Qt.callLater(card.selectFirst);
    }

    function cardAt(level) {
        return cards.itemAt(level)?.menu ?? null; // qmllint disable missing-property
    }

    function push(path, anchor, selectFirst) {
        stack = stack.concat([
            {
                path: path,
                anchor: anchor,
                selectFirst: selectFirst === true
            }
        ]);
        levels.append({});
    }

    // Close every card deeper than level.
    function truncate(level) {
        if (stack.length <= level)
            return;
        const removed = stack.length - level;
        stack = stack.slice(0, level);
        levels.remove(level, removed);
        cardAt(level - 1)?.focusSearch();
    }

    function pop() {
        if (stack.length <= 1)
            close();
        else
            truncate(stack.length - 1);
    }

    function childPath(level, row) {
        return stack[level].path.concat(row.trail || [], [row.key]);
    }

    function isOpen(level, row) {
        const open = stack[level + 1];
        return !!open && !!row && open.path.join("\n") === childPath(level, row).join("\n");
    }

    function openChild(level, row, selectFirst) {
        if (isOpen(level, row))
            return;
        truncate(level + 1);
        const frame = cards.itemAt(level);
        if (frame)
            push(childPath(level, row), frame.rowAnchor(frame.menu.current), selectFirst); // qmllint disable missing-property
    }

    // Delays hover-opening so a diagonal move toward a submenu does not switch it.
    property var hoverTarget: null

    Timer {
        id: hoverTimer
        interval: 150
        onTriggered: {
            const target = overlay.hoverTarget;
            const card = target && target.level < overlay.stack.length ? overlay.cardAt(target.level) : null;
            if (card && card.current === target.index)
                overlay.openChild(target.level, card.shownRows[target.index]);
        }
    }

    function hover(level, index) {
        const row = cardAt(level).shownRows[index];
        if (stack.length > level + 1 && !isOpen(level, row))
            truncate(level + 1);
        hoverTarget = row && row.hasChildren && row.enabled ? {
            level: level,
            index: index
        } : null;
        if (hoverTarget)
            hoverTimer.restart();
    }

    // A press outside the cards closes the menu; a right-press then reaches
    // what is below, so another row's menu opens there.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            overlay.close();
            mouse.accepted = mouse.button === Qt.LeftButton;
        }
    }

    Rectangle {
        id: frame

        visible: !overlay.context
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
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
            text: [overlay.title].concat(overlay.tree.names, overlay.level.names).join(" › ")
        }

        MenuCard {
            id: card
            x: 4
            y: breadcrumb.y + breadcrumb.height + 4
            width: parent.width - 8
            height: parent.height - y - 4
            shell: overlay.shell
            rows: overlay.visible && !overlay.context ? Model.search(overlay.level.rows, card.query) : []
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
            onRunRequested: row => overlay.run(row)
            onBackRequested: {
                if (overlay.path.length)
                    overlay.drill(overlay.path.slice(0, -1));
                else
                    overlay.close();
            }
            onCloseRequested: overlay.close()
        }
    }

    ListModel {
        id: levels
    }

    Repeater {
        id: cards
        model: levels

        Rectangle {
            id: cascade

            required property int index
            readonly property alias menu: menu

            // Read once: a push must not rebuild this card's rows.
            property var entry: null
            Component.onCompleted: {
                entry = overlay.stack[index];
                if (entry.selectFirst)
                    menu.selectFirst();
                menu.settle();
                menu.focusSearch();
            }
            readonly property var level: entry ? Model.level(overlay.tree.rows, entry.path) : {
                rows: [],
                names: []
            }

            // Placed by its tallest height, so a query shrinks the card without moving
            // its top, or its bottom when it hangs above its anchor.
            property real tallest: 0
            onHeightChanged: tallest = Math.max(tallest, height)
            readonly property var position: !entry ? Qt.point(0, 0) : index ? Model.place(entry.anchor, width, tallest, overlay.width, overlay.height) : Model.hang(entry.anchor, width, tallest, overlay.width, overlay.height)

            // Anchor for the submenu of row, in the overlay's coordinates.
            function rowAnchor(row) {
                return {
                    x: cascade.x,
                    width: cascade.width,
                    y: overlay.mapFromItem(null, 0, menu.rowTop(row)).y
                };
            }

            x: position.x
            y: position.above ? position.y + tallest - height : position.y
            width: Model.clamp(Math.ceil(menu.implicitWidth) + 12, 160, 360)
            height: Math.max(40, Math.min(menu.implicitHeight + 12, overlay.height - 16))
            radius: 8
            color: overlay.shell.palette.bg
            border.color: overlay.shell.palette.dim
            border.width: 1

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
            }

            MenuCard {
                id: menu
                anchors.fill: parent
                anchors.margins: 6
                shell: overlay.shell
                rows: cascade.entry ? Model.search(cascade.level.rows, menu.query) : []
                placeholder: cascade.level.names.length ? "Filter " + cascade.level.names[cascade.level.names.length - 1].toLowerCase() + "…" : "Filter…"
                maxWidth: 360 - 12

                // A query changes this card's rows, so its submenus no longer belong.
                onQueryChanged: overlay.truncate(cascade.index + 1)
                onOpenRequested: (row, selectFirst) => overlay.openChild(cascade.index, row, selectFirst)
                onRunRequested: row => overlay.run(row)
                onBackRequested: overlay.pop()
                onCloseRequested: overlay.close()
                onHovered: index => overlay.hover(cascade.index, index)
            }
        }
    }
}
