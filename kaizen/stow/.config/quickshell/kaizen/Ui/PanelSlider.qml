import QtQuick

// A value from 0 to 1 on a thin track, filled up to it (style.md › Panels).
Item {
    id: slider

    required property var shell
    property real value: 0
    // Muted or off: the fill and knob turn `off`.
    property bool off: false
    property bool focused: false
    // False for a meter: no knob, no pointer.
    property bool interactive: true
    property string icon: ""
    property color iconColor: shell.palette.fg

    property color fillColor: off ? shell.palette.off : shell.palette.fg
    // Drawn right of the track; empty draws no column.
    property string valueText: ""
    property color valueColor: fillColor

    signal moved(real value)
    signal hovered

    width: parent ? parent.width : 0
    implicitHeight: 32

    // The fill reaches into the card's padding, so the icon aligns with the section label.
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: 4
        color: slider.focused ? slider.shell.palette.sel : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        enabled: slider.interactive
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        onEntered: slider.hovered()
    }

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: slider.iconColor
        font.family: Fonts.mono
        font.pixelSize: 14
        text: slider.icon
    }

    Item {
        id: track
        anchors.left: iconText.right
        anchors.leftMargin: 8
        anchors.right: valueLabel.visible ? valueLabel.left : parent.right
        // Room for the knob's half at full, and the gap before the value.
        anchors.rightMargin: (slider.interactive ? 5 : 0) + (valueLabel.visible ? 8 : 0)
        anchors.verticalCenter: parent.verticalCenter
        height: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 2
            radius: 1
            color: slider.shell.palette.dim
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * Math.max(0, Math.min(1, slider.value))
            height: 2
            radius: 1
            color: slider.fillColor
        }

        Rectangle {
            visible: slider.interactive
            x: parent.width * Math.max(0, Math.min(1, slider.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: slider.fillColor
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -11
            anchors.bottomMargin: -11
            enabled: slider.interactive
            hoverEnabled: true
            onEntered: slider.hovered()
            onPressed: function (mouse) {
                slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
            }
            onPositionChanged: function (mouse) {
                if (pressed)
                    slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
            }
        }
    }

    // As wide as "100%", so stacked tracks end at the same x.
    TextMetrics {
        id: widest
        font: valueLabel.font
        text: "100%"
    }

    Text {
        id: valueLabel
        visible: slider.valueText !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: widest.advanceWidth
        horizontalAlignment: Text.AlignRight
        color: slider.valueColor
        font.family: Fonts.mono
        font.pixelSize: 14
        text: slider.valueText
    }
}
