import QtQuick
import QtQuick.Controls
import QtQuick.Window

// A panel's scrolling body, between its fixed header and footer: a column of its children, as tall as they are up
// to `maxHeight`, then scrolling to keep the focused item in view, the bar in the card's right padding
// (style.md › Panels). It sits in its view's Column.
Item {
    id: scroller

    required property var shell
    // What the screen leaves at the text scale, less the view's other items, their spacing and the card's padding.
    // Sums the siblings, not the view's height, which holds this one's.
    property real maxHeight: {
        const view = scroller.parent;
        if (!view)
            return 0;
        let rest = 2 * Space.cardPadding;
        for (const item of view.children)
            if (item !== scroller && item.visible && item.height > 0)
                rest += item.height + view.spacing;
        return Math.max(0, Space.cardRoom(scroller.Window.height, shell.barHeight) / shell.textScale - rest);
    }
    // How far past the sides, and past an end with nothing scrolled beyond it, the body draws: a glowing card's halo.
    property int bleed: 0
    property alias spacing: body.spacing
    default property alias content: body.data

    // Focus moved onto an item in the body.
    signal focusEntered(Item item)

    width: parent ? parent.width : 0
    implicitHeight: flickable.height

    // 16 wider than the content, so a row's `sel` fill reaching into the card's padding is not clipped.
    Item {
        id: clipper

        readonly property real above: flickable.atYBeginning ? scroller.bleed : 0

        x: -8 - scroller.bleed
        y: -above
        width: scroller.width + 16 + 2 * scroller.bleed
        height: flickable.height + above + (flickable.atYEnd ? scroller.bleed : 0)
        clip: true

        Flickable {
            id: flickable

            readonly property var focusedItem: flickable.Window.activeFocusItem

            function holds(item) {
                for (let candidate = item; candidate; candidate = candidate.parent)
                    if (candidate === body)
                        return true;
                return false;
            }

            // Only items in the body: focus outside it (the card, a view being replaced) scrolls nothing.
            // Map to content coordinates: Flickable coordinates are relative to its viewport.
            onFocusedItemChanged: {
                const item = focusedItem;
                if (!item || !visible || !holds(item))
                    return;
                scroller.focusEntered(item);
                const top = item.mapToItem(body, 0, 0).y;
                if (top < contentY)
                    contentY = Math.max(0, top);
                else if (top + item.height > contentY + height)
                    contentY = top + item.height - height;
            }

            x: scroller.bleed
            y: clipper.above
            width: scroller.width + 16
            height: Math.min(body.implicitHeight, scroller.maxHeight)
            contentWidth: width
            contentHeight: body.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: scrollBar

            Column {
                id: body

                x: 8
                width: scroller.width
                spacing: 24
            }
        }
    }

    PanelScrollBar {
        id: scrollBar
        x: scroller.width + 10
        height: flickable.height
        shell: scroller.shell
    }
}
