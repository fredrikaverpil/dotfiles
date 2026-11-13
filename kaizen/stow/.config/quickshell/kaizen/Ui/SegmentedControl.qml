import QtQuick

// One choice of a few, side by side in one outline; the chosen label is `fg`, the others `off`, unavailable ones `dim` (style.md › Panels).
Rectangle {
    id: control

    required property var shell
    // [{ value: "balanced", label: "󰊚 Balanced" }, ...]
    property var options: []
    property var current
    property var matches: (value, current) => value === current
    // False draws an option `dim`, skipped by focus. A function, so the options and their focus outlive a change of it.
    property var available: value => true

    // Segments share the spare width equally, so each label has the same space around it.
    readonly property real spare: (width - options.reduce((sum, option) => sum + metrics.advanceWidth(option.label), 0)) / Math.max(1, options.length)

    signal picked(var value)

    width: parent ? parent.width : 0
    implicitHeight: 28
    radius: 4
    color: "transparent"
    border.width: 1
    border.color: shell.palette.dim

    FontMetrics {
        id: metrics
        font.family: Fonts.mono
        font.pixelSize: 14
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: control.options

            delegate: Item {
                id: segment

                required property var modelData
                readonly property bool chosen: control.matches(modelData.value, control.current)
                readonly property bool available: control.available(modelData.value)

                function pick() {
                    if (available)
                        control.picked(modelData.value);
                }

                width: metrics.advanceWidth(modelData.label) + control.spare
                height: control.height

                activeFocusOnTab: (control.visible && segment.available) || segment.activeFocus
                Keys.onReturnPressed: segment.pick()
                Keys.onEnterPressed: segment.pick()
                Keys.onSpacePressed: segment.pick()

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 3
                    color: segment.activeFocus || (segment.available && mouse.containsMouse) ? control.shell.palette.sel : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    color: !segment.available ? control.shell.palette.dim : segment.chosen ? control.shell.palette.fg : control.shell.palette.off
                    font.family: Fonts.mono
                    font.pixelSize: 14
                    text: segment.modelData.label
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: segment.pick()
                }
            }
        }
    }
}
