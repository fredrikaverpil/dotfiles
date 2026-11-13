pragma Singleton

import QtQuick

// Panel spacing every view shares (style.md › Panels › Space).
QtObject {
    readonly property int cardPadding: 16
    // A sub-group's heading and rows inside its group (Ui.Subsection).
    readonly property int indent: 16
}
