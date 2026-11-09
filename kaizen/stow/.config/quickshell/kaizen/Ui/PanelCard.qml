import QtQuick
import QtQuick.Window

// A panel's card, apart from its layer surface so the gallery can draw it in a window.
Rectangle {
    id: card

    required property var shell
    property bool keyNavigation: false
    property int padding: 12

    default property alias content: column.data
    readonly property alias body: column
    readonly property alias contentSpacing: column.spacing

    signal closeRequested

    function focusContent() {
        column.forceActiveFocus();
    }

    function focusStep(forward) {
        const current = column.Window.activeFocusItem;
        if (!current) {
            column.forceActiveFocus();
            return;
        }
        const next = current.nextItemInFocusChain(forward);
        if (next)
            next.forceActiveFocus(Qt.TabFocusReason);
    }

    radius: 8
    color: shell.palette.bg
    border.color: shell.palette.dim
    border.width: 1

    Keys.onPressed: function (event) {
        if (!card.keyNavigation)
            return;
        if (event.key === Qt.Key_Escape)
            card.closeRequested();
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.text === "j" || event.text === "l")
            card.focusStep(true);
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.text === "k" || event.text === "h")
            card.focusStep(false);
        else
            return;
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: card.padding
        spacing: 8

        focus: card.keyNavigation
    }
}
