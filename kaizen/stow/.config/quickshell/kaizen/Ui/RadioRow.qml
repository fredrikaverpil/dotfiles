import QtQuick

// One choice of a set: `●` when chosen, `○` in `dim` otherwise (style.md › Panels).
Item {
    id: row

    required property var shell
    property string label: ""
    property bool chosen: false
    property bool focused: false

    signal hovered
    signal activated

    width: parent ? parent.width : 0
    implicitHeight: 28

    // The fill reaches into the card's padding, so the mark aligns with the section label.
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: 4
        color: row.focused ? row.shell.palette.sel : "transparent"
    }

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
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        color: row.shell.palette.fg
        font.family: Fonts.mono
        font.pixelSize: 14
        text: row.label
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        hoverEnabled: true
        onEntered: row.hovered()
        onClicked: row.activated()
    }
}
