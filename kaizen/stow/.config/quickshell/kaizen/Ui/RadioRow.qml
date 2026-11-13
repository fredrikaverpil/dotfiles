import QtQuick

// One choice of a set: `●` when chosen, `○` in `dim` otherwise (style.md › Panels).
PanelRow {
    id: row

    property string label: ""
    property bool chosen: false
    // At the row's right, such as a player's state.
    property string value: ""
    property color valueColor: shell.palette.off

    Text {
        id: mark
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: row.chosen ? row.shell.palette.fg : row.shell.palette.dim
        font.family: Fonts.mono
        font.pixelSize: 12
        text: row.chosen ? "●" : "○"
    }

    Text {
        anchors.left: mark.right
        anchors.leftMargin: 8
        anchors.right: valueText.left
        anchors.rightMargin: valueText.text ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        color: row.shell.palette.fg
        font.family: Fonts.mono
        font.pixelSize: 14
        text: row.label
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: row.valueColor
        font.family: Fonts.mono
        font.pixelSize: 14
        text: row.value
    }
}
