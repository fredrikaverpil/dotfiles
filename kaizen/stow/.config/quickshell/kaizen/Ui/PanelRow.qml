import QtQuick

// A row that is a focus stop: hover takes focus, the `sel` fill marks it, and Enter, Space or a click activates it
// (style.md › Panels). Its children draw over the fill.
Item {
    id: row

    required property var shell
    // Draws the fill; a view keeping its own cursor (audio's) binds it.
    property bool focused: activeFocus

    signal hovered
    signal activated

    width: parent ? parent.width : 0
    implicitHeight: 28

    // Kept while focused: Qt refuses to drop the active focus item from the chain.
    activeFocusOnTab: row.visible || row.activeFocus
    Keys.onReturnPressed: row.activated()
    Keys.onEnterPressed: row.activated()
    Keys.onSpacePressed: row.activated()

    // The fill reaches into the card's padding, so the text aligns with the rule.
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: 4
        color: row.focused ? row.shell.palette.sel : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        hoverEnabled: true
        onEntered: {
            row.hovered();
            row.forceActiveFocus();
        }
        onClicked: row.activated()
    }
}
