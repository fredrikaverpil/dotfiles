import QtQuick
import QtQuick.Window

// A panel's card, apart from its layer surface.
Rectangle {
    id: card

    required property var shell
    property bool keyNavigation: false

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

    // Takes focus back when the focused item goes (a row whose entry left), so the card's keys keep working.
    FocusScope {
        anchors.fill: parent
        anchors.margins: Space.cardPadding
        focus: card.keyNavigation

        Column {
            id: column
            anchors.fill: parent
            spacing: 8

            focus: card.keyNavigation
        }
    }
}
