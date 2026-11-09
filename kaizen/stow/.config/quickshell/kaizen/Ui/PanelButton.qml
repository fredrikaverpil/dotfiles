import QtQuick

// A panel's button: outlined `dim`, filled `sel` on focus or hover (style.md › Panels).
Rectangle {
    id: button

    required property var shell
    property string label: ""

    signal activated

    implicitWidth: text.implicitWidth + 24
    implicitHeight: 28
    radius: 4
    color: button.activeFocus || mouse.containsMouse ? shell.palette.sel : "transparent"
    border.width: 1
    border.color: shell.palette.dim

    activeFocusOnTab: button.visible
    Keys.onReturnPressed: button.activated()
    Keys.onEnterPressed: button.activated()
    Keys.onSpacePressed: button.activated()

    Text {
        id: text
        anchors.centerIn: parent
        color: button.shell.palette.fg
        font.family: Fonts.mono
        font.pixelSize: 14
        text: button.label
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.activated()
    }
}
