import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "MenuCardModel.js" as Model

// Cascading menu anchored to what opened it. Not a Panel: a panel's card is centered, while
// these cards follow their anchor and open submenus beside their row.
PanelWindow {
    id: root

    required property var shell
    property bool shown: false

    // Rows heading the root menu, shaped like QsMenuEntry.
    property var headRows: []
    // One level per open card: { opener, source, anchor, title, selectFirst }.
    property var stack: []
    readonly property int depth: stack.length
    readonly property real zoom: shell.textScale

    function close() {
        shown = false;
    }

    function cardAt(level) {
        return cards.itemAt(level)?.menu ?? null; // qmllint disable missing-property
    }

    // Launcher rows come from rows(query); tray entries from an opener, filtered by text.
    function rowsFor(entry, level, query) {
        const entries = entry.source.rows ? entry.source.rows(query) : entry.opener.children ? entry.opener.children.values : [];
        const head = level === 0 ? headRows : [];
        if (!query)
            return head.concat(entries);
        const found = row => !row.isSeparator && Model.matches(row, query);
        return head.filter(found).concat(entry.source.rows ? entries : entries.filter(found));
    }

    // Child entries belong to their parent opener, so every menu level needs its own opener.
    Component {
        id: openerComponent
        QsMenuOpener {}
    }

    function push(handle, anchor, selectFirst) {
        const opener = handle.rows ? null : openerComponent.createObject(root, {
            menu: handle
        });
        if (!handle.rows && !opener)
            return;
        stack = stack.concat([
            {
                opener: opener,
                source: handle,
                anchor: anchor,
                title: handle.text || handle.title || "",
                selectFirst: selectFirst === true
            }
        ]);
        levels.append({});
    }

    // Close every card deeper than level.
    function truncate(level) {
        if (depth <= level)
            return;
        // Clear bindings before destroying openers, deepest first.
        const removed = stack.slice(level);
        stack = stack.slice(0, level);
        levels.remove(level, removed.length);
        for (let i = removed.length - 1; i >= 0; i--)
            removed[i].opener?.destroy();
        cardAt(level - 1)?.focusSearch();
    }

    function pop() {
        if (depth <= 1)
            close();
        else
            truncate(depth - 1);
    }

    function reset() {
        hoverTimer.stop();
        truncate(0);
    }

    // Opens handle's menu on output (a screen name), at anchorFor(output): a bar button as
    // { below: true, x, width } in window coordinates, or null to center. Without an
    // output the menu opens on the focused one. handle is a tray menu handle, or
    // { rows, title } whose rows(query) returns rows shaped like QsMenuEntry plus a
    // glyph, image, detail, keys and a key.
    function popup(handle, output, anchorFor) {
        if (!output) {
            pending = {
                handle: handle,
                anchorFor: anchorFor
            };
            focusedOutput.running = true;
            return;
        }
        shown = false;
        reset();
        screen = Quickshell.screens.find(candidate => candidate.name === output) || null;
        push(handle, anchorFor ? anchorFor(output) : null);
        if (shell && shell.registerPanel)
            shell.registerPanel(root);
        if (shell && shell.claimPanel)
            shell.claimPanel(root);
        shown = true;
    }

    property var pending: null

    Process {
        id: focusedOutput
        command: Compositor.outputs()
        stdout: StdioCollector {
            onStreamFinished: {
                const monitor = Compositor.focusedMonitor(text);
                const request = root.pending;
                root.pending = null;
                if (monitor && request)
                    root.popup(request.handle, monitor.name, request.anchorFor);
            }
        }
    }

    // A row without an action (a keybinding) is there to read.
    function run(row) {
        if (!row.triggered)
            return;
        row.triggered();
        close();
    }

    function openChild(level, row, selectFirst) {
        const open = stack[level + 1];
        if (open && Model.sameRow(open.source, row))
            return;
        truncate(level + 1);
        const card = cards.itemAt(level);
        if (card)
            push(row, card.rowAnchor(card.menu.current), selectFirst); // qmllint disable missing-property
    }

    // Delays hover-opening so a diagonal move toward a submenu does not switch it.
    property var hoverTarget: null

    Timer {
        id: hoverTimer
        interval: 150
        onTriggered: {
            const target = root.hoverTarget;
            const card = target && target.level < root.depth ? root.cardAt(target.level) : null;
            if (card && card.current === target.index)
                root.openChild(target.level, card.shownRows[target.index]);
        }
    }

    function hover(level, index) {
        const row = cardAt(level).shownRows[index];
        const open = stack[level + 1];
        if (open && !Model.sameRow(open.source, row))
            truncate(level + 1);
        hoverTarget = row && row.hasChildren && row.enabled ? {
            level: level,
            index: index
        } : null;
        if (hoverTarget)
            hoverTimer.restart();
    }

    onShownChanged: if (shown)
        cardAt(depth - 1)?.focusSearch()
    else
        reset()

    visible: shown
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    // Keeps the bar's exclusive zone, so the area starts at the bar's bottom edge.
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    // Demoting an exclusive panel loses its keyboard focus on niri.
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        enabled: root.shown
        onClicked: root.close()
    }

    ListModel {
        id: levels
    }

    Repeater {
        id: cards
        model: levels

        Rectangle {
            id: frame

            required property int index
            readonly property alias menu: menu

            // Read once: stack changes must not rebuild this card's rows.
            property var level: null
            Component.onCompleted: {
                level = root.stack[index];
                if (level.selectFirst)
                    menu.selectFirst();
                menu.settle();
                menu.focusSearch();
            }

            // Placed by its tallest height, so a query shrinks the card without moving its top.
            property real tallest: 0
            onHeightChanged: tallest = Math.max(tallest, height)
            readonly property var position: Model.place(level ? level.anchor : null, width * root.zoom, tallest * root.zoom, root.width, root.height)

            // Anchor for the submenu of row, in window coordinates.
            function rowAnchor(row) {
                return {
                    x: frame.x,
                    width: frame.width * root.zoom,
                    y: menu.rowTop(row)
                };
            }

            x: position.x
            y: position.y
            width: Model.clamp(Math.ceil(menu.implicitWidth) + 12, 160, 360)
            height: Math.max(40, Math.min(menu.implicitHeight + 12, (root.height - 16) / root.zoom))
            scale: root.zoom
            transformOrigin: Item.TopLeft
            radius: 8
            // A card below a bar button hangs from the bar.
            readonly property bool hangs: level && level.anchor ? level.anchor.below === true : false
            topLeftRadius: hangs ? 0 : radius
            topRightRadius: hangs ? 0 : radius
            color: root.shell.palette.bg
            border.color: root.shell.palette.dim
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            MenuCard {
                id: menu
                anchors.fill: parent
                anchors.margins: 6
                shell: root.shell
                rows: frame.level ? root.rowsFor(frame.level, frame.index, menu.query) : []
                placeholder: frame.level && frame.level.title ? "Filter " + frame.level.title.toLowerCase() + "…" : "Filter…"
                maxWidth: 360 - 12

                // A query changes this card's rows, so its submenus no longer belong.
                onQueryChanged: root.truncate(frame.index + 1)
                onOpenRequested: (row, selectFirst) => root.openChild(frame.index, row, selectFirst)
                onRunRequested: row => root.run(row)
                onBackRequested: root.pop()
                onCloseRequested: root.close()
                onHovered: index => root.hover(frame.index, index)
            }
        }
    }
}
