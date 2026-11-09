import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The services, or the gallery's stand-in.
    required property var brightness
    required property var nightlight
    required property var mirror
    // focused: the focused monitor or null; names: every output's name.
    required property var outputs

    // wdisplays arranges the outputs; the panel closes for it.
    signal arrangeRequested
    signal wallpaperRequested

    readonly property var textScales: [0.9, 1, 1.1, 1.25, 1.5, 2]

    readonly property int cardWidth: 600
    readonly property int cardHeight: 440 + layoutSection.height + spacing + (mirrorSection.visible ? mirrorSection.height + spacing : 0)
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 8

    Text {
        width: parent.width
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 18
        text: "Display"
    }

    Text {
        width: parent.width
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: root.outputs.focused ? root.outputs.focused.name + " · " + root.outputs.focused.width + "×" + root.outputs.focused.height : "No active display"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Ui.Section {
        shell: root.shell
        title: "Theme"

        ChoiceRow {
            options: [
                {
                    label: "Light",
                    value: false
                },
                {
                    label: "Dark",
                    value: true
                },
            ]
            selected: root.shell.dark
            onChosen: value => root.shell.setDark(value)
        }
    }

    Ui.Section {
        shell: root.shell
        title: root.nightlight.temperature === null ? "Nightlight" : "Nightlight · " + root.nightlight.temperature + "K"

        ChoiceRow {
            options: [
                {
                    label: "Off",
                    value: "off"
                },
                {
                    label: "Auto",
                    value: "auto"
                },
                {
                    label: "On",
                    value: "on"
                },
            ]
            selected: root.nightlight.mode
            onChosen: value => root.nightlight.setMode(value)
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Text size · " + Math.round(root.shell.textScale * 100) + "%"

        ChoiceRow {
            options: root.textScales.map(value => ({
                        label: Math.round(value * 100) + "%",
                        value: value
                    }))
            selected: root.shell.textScale
            matches: (value, selected) => Math.abs(Number(value) - Number(selected)) < 0.01
            onChosen: value => root.shell.setTextScale(value)
        }
    }

    Ui.Section {
        shell: root.shell
        title: root.brightness.present ? "Brightness · " + root.brightness.percent + "%" : "Brightness · not applicable, no backlight device"

        Rectangle {
            id: brightnessSlider

            visible: root.brightness.present
            width: parent.width
            height: 30
            radius: 4
            color: "transparent"
            border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1

            activeFocusOnTab: visible
            // Left/right adjust here; up/down fall through to the panel's focus chain.
            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Right || event.text === "l")
                    root.brightness.adjust(root.brightness.step);
                else if (event.key === Qt.Key_Left || event.text === "h")
                    root.brightness.adjust(-root.brightness.step);
                else
                    return;
                event.accepted = true;
            }

            Text {
                id: brightnessIcon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 16
                text: "󰃠"
            }

            Rectangle {
                anchors.left: brightnessIcon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: root.shell.palette.dim

                Rectangle {
                    width: parent.width * root.brightness.percent / 100
                    height: parent.height
                    radius: parent.radius
                    color: root.shell.palette.fg
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    onPositionChanged: function (mouse) {
                        if (pressed)
                            root.brightness.set(100 * mouse.x / width);
                    }
                    onPressed: function (mouse) {
                        root.brightness.set(100 * mouse.x / width);
                    }
                }
            }
        }
    }

    Ui.Section {
        id: mirrorSection

        visible: root.outputs.names.length > 1
        shell: root.shell
        title: "Mirror"

        // One row per output, picking what it shows.
        Repeater {
            model: root.outputs.names

            delegate: Row {
                id: mirrorRow

                required property string modelData
                readonly property string target: modelData

                width: root.width
                spacing: 6

                Text {
                    width: 90
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    text: mirrorRow.target
                }

                ChoiceRow {
                    width: parent.width - 96
                    available: !root.mirror.busy
                    options: [
                        {
                            label: "Own",
                            value: ""
                        }
                    ].concat(root.outputs.names.filter(name => name !== mirrorRow.target).map(name => ({
                                label: name,
                                value: name,
                                available: root.mirror.sourceOf(mirrorRow.target) === name || root.mirror.canMirror(name, mirrorRow.target)
                            })))
                    selected: root.mirror.sourceOf(mirrorRow.target)
                    onChosen: value => value ? root.mirror.start(value, mirrorRow.target) : root.mirror.stop(mirrorRow.target)
                }
            }
        }
    }

    Ui.Section {
        id: layoutSection

        shell: root.shell
        title: "Layout"

        ChoiceButton {
            width: parent.width
            label: "Arrange outputs…"
            onActivated: root.arrangeRequested()
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Wallpaper · " + (root.shell.dark ? "dark" : "light")

        ChoiceButton {
            width: parent.width
            label: "Choose wallpaper…"
            onActivated: root.wallpaperRequested()
        }
    }

    component ChoiceRow: Row {
        id: choices

        property var options: []
        property var selected
        property bool available: true
        property var matches: (value, selected) => value === selected
        signal chosen(var value)

        width: parent.width
        spacing: 6

        Repeater {
            id: optionRepeater
            model: choices.options

            delegate: ChoiceButton {
                required property var modelData
                required property int index

                width: (choices.width - choices.spacing * (optionRepeater.count - 1)) / optionRepeater.count
                label: modelData.label
                active: choices.matches(modelData.value, choices.selected)
                available: choices.available && modelData.available !== false
                onActivated: choices.chosen(modelData.value)
            }
        }
    }

    component ChoiceButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        property bool available: true
        signal activated

        height: 30
        radius: 4
        color: active ? root.shell.palette.sel : "transparent"
        border.color: button.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        opacity: available ? 1 : 0.45

        // Keep an unavailable visible button in the chain; removing focused controls strands focus.
        activeFocusOnTab: true
        Keys.onReturnPressed: if (button.available)
            button.activated()
        Keys.onEnterPressed: if (button.available)
            button.activated()
        Keys.onSpacePressed: if (button.available)
            button.activated()

        Text {
            anchors.centerIn: parent
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: button.label
        }

        MouseArea {
            anchors.fill: parent
            enabled: button.available
            hoverEnabled: true
            onClicked: button.activated()
        }
    }
}
