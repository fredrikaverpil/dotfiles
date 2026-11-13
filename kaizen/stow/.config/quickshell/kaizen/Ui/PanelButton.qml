import QtQuick

// A panel's button: outlined `dim`, filled `sel` on focus or hover; `dim` and skipped by focus while it cannot act
// (style.md › Panels).
Rectangle {
    id: button

    required property var shell
    property string label: ""
    property bool available: true
    // The button is at least as wide as this label, so it keeps its place when its label changes.
    property string widest: ""

    signal activated

    implicitWidth: Math.max(caption.implicitWidth, widestMetrics.advanceWidth) + 24
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
        id: caption
        anchors.centerIn: parent
        color: button.available ? button.shell.palette.fg : button.shell.palette.dim
        font.family: Fonts.mono
        font.pixelSize: 14
        text: button.label
    }

    TextMetrics {
        id: widestMetrics
        font: caption.font
        text: button.widest
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: button.available
        hoverEnabled: true
        onClicked: button.activated()
    }
}
