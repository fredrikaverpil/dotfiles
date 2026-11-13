pragma Singleton

import QtQuick

// Panel spacing every view shares (style.md › Panels › Space).
QtObject {
    readonly property int cardPadding: 16
    // A sub-group's heading and rows inside its group (Ui.Subsection).
    readonly property int indent: 16

    // The height a card may take in a window of `height`: clear of the bar, as much again below, and 16 from each edge.
    function cardRoom(height, barHeight) {
        return height - 2 * barHeight - 32;
    }
}
