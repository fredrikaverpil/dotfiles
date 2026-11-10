import QtQuick

// A panel's button: outlined `dim`, filled `sel` on focus or hover; `dim` and skipped by focus while it cannot act
// (style.md › Panels).
Rectangle {
    id: button

    required property var shell
    property string label: ""
    property bool available: true

    signal activated

    implicitWidth: text.implicitWidth + 24
    implicitHeight: 28
    radius: 4
    color: button.available && (button.activeFocus || mouse.containsMouse) ? shell.palette.sel : "transparent"
    border.width: 1
    border.color: shell.palette.dim

    // Kept while focused: Qt refuses to drop the active focus item from the chain.
    activeFocusOnTab: (button.visible && button.available) || button.activeFocus
    Keys.onReturnPressed: if (button.available)
        button.activated()
    Keys.onEnterPressed: if (button.available)
        button.activated()
    Keys.onSpacePressed: if (button.available)
        button.activated()

    Text {
        id: text
        anchors.centerIn: parent
        color: button.available ? button.shell.palette.fg : button.shell.palette.dim
        font.family: Fonts.mono
        font.pixelSize: 14
        text: button.label
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.available
        hoverEnabled: true
        onClicked: button.activated()
    }
}
