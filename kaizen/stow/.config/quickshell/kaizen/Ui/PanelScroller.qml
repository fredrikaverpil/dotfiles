import QtQuick
import QtQuick.Controls
import QtQuick.Window

// A panel's scrolling body, between its fixed header and footer: a column of its children, as tall as they are up
// to `maxHeight`, then scrolling to keep the focused item in view, the bar in the card's right padding
// (style.md › Panels).
Item {
    id: scroller

    required property var shell
    property int maxHeight: 520
    property alias spacing: body.spacing
    default property alias content: body.data

    // Focus moved onto an item in the body.
    signal focusEntered(Item item)

    width: parent ? parent.width : 0
    implicitHeight: flickable.height

    // 16 wider than the content, so a row's `sel` fill reaching into the card's padding is not clipped.
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

        x: -8
        width: scroller.width + 16
        height: Math.min(body.implicitHeight, scroller.maxHeight)
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: scrollBar

        Column {
            id: body

            x: 8
            width: scroller.width
            spacing: 24
        }
    }

    PanelScrollBar {
        id: scrollBar
        x: scroller.width + 10
        height: flickable.height
        shell: scroller.shell
    }
}
