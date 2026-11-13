import QtQuick
import QtQuick.Layouts

import "InfoTableModel.js" as Model

// Labelled values, all 14 px: labels `off`, values `fg` (or their status role) right-aligned in their
// columns (style.md › Panels).
GridLayout {
    id: table

    required property var shell
    // [{ label, value, role }]
    property var entries: []
    // Entries side by side.
    property int perLine: 1
    // Each column's width; tables given the same (Model.columnWidths over all of them) line up.
    property var widths: Model.columnWidths([entries], perLine, text => metrics.advanceWidth(text))

    // widths within the table's own, so a value too long for the card (an SSID) elides.
    readonly property var fitted: Model.fitWidths(widths, width, columnSpacing)

    width: parent ? parent.width : 0
    columns: perLine * 2
    columnSpacing: 16
    rowSpacing: 4

    FontMetrics {
        id: metrics
        font.family: Fonts.mono
        font.pixelSize: 14
    }

    Repeater {
        model: Model.cells(table.entries, table.perLine)

        delegate: Text {
            required property var modelData

            Layout.fillWidth: modelData.label
            Layout.preferredWidth: table.fitted[modelData.column] || 0
            horizontalAlignment: modelData.label ? Text.AlignLeft : Text.AlignRight
            elide: Text.ElideRight
            // An unknown role reads as the default rather than no colour.
            color: table.shell.palette[modelData.role] || table.shell.palette.fg
            font: metrics.font
            text: modelData.text
        }
    }
}
