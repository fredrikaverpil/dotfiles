import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The services.
    required property var brightness
    required property var nightlight
    required property var mirror
    // focused: the focused monitor or null; names: every output's name.
    required property var outputs

    // wdisplays arranges the outputs; the panel closes for it.
    signal arrangeRequested
    signal wallpaperRequested

    readonly property var textScales: [0.9, 1, 1.1, 1.25, 1.5, 2]

    readonly property int cardWidth: 400
    readonly property bool keyNavigation: true

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Display"
        subtitle: root.outputs.focused ? root.outputs.focused.name + " · " + root.outputs.focused.width + "×" + root.outputs.focused.height : "No active display"
    }

    // A group, not the header's slider (style.md › Panels › Form): the panel has no key value, and only the backlit
    // output has brightness. Shown on that output; on every output when sysfs names none.
    Ui.Section {
        visible: root.brightness.present && (root.brightness.output === "" || !!root.outputs.focused && root.outputs.focused.name === root.brightness.output)
        shell: root.shell
        title: "Brightness"

        Ui.PanelSlider {
            id: brightnessSlider
            shell: root.shell
            value: root.brightness.percent / 100
            valueText: root.brightness.percent + "%"
            icon: "󰃠"
            onMoved: value => root.brightness.set(100 * value)
            onStepped: direction => root.brightness.adjust(direction * root.brightness.step)
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Theme"

        Ui.SegmentedControl {
            shell: root.shell
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
            current: root.shell.dark
            onPicked: value => root.shell.setDark(value)
        }

        Ui.PanelButton {
            shell: root.shell
            label: "Choose wallpaper…"
            onActivated: root.wallpaperRequested()
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Nightlight"
        value: root.nightlight.temperature === null ? "" : root.nightlight.temperature + "K"

        Ui.SegmentedControl {
            shell: root.shell
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
            current: root.nightlight.mode
            onPicked: value => root.nightlight.setMode(value)
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Text size"

        Ui.SegmentedControl {
            shell: root.shell
            options: root.textScales.map(value => ({
                        label: Math.round(value * 100) + "%",
                        value: value
                    }))
            current: root.shell.textScale
            matches: (value, current) => Math.abs(value - current) < 0.01
            onPicked: value => root.shell.setTextScale(value)
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Outputs"

        // One row per output, picking what it shows; only with another output to mirror.
        Column {
            visible: root.outputs.names.length > 1
            width: parent.width
            spacing: 4

            Repeater {
                model: root.outputs.names.length > 1 ? root.outputs.names : []

                delegate: Item {
                    id: mirrorRow

                    required property string modelData
                    readonly property string target: modelData

                    width: root.width
                    implicitHeight: mirrorChoice.implicitHeight

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: mirrorRow.target
                    }

                    Ui.SegmentedControl {
                        id: mirrorChoice
                        anchors.right: parent.right
                        // Every row's segments as wide as the longest name (the font is monospace), so the rows align.
                        width: implicitWidth
                        widest: root.outputs.names.reduce((widest, name) => name.length > widest.length ? name : widest, "Own")
                        shell: root.shell
                        options: [
                            {
                                label: "Own",
                                value: ""
                            }
                        ].concat(root.outputs.names.filter(name => name !== mirrorRow.target).map(name => ({
                                    label: name,
                                    value: name
                                })))
                        available: value => !root.mirror.busy && (value === "" || root.mirror.sourceOf(mirrorRow.target) === value || root.mirror.canMirror(value, mirrorRow.target))
                        current: root.mirror.sourceOf(mirrorRow.target)
                        onPicked: value => value ? root.mirror.start(value, mirrorRow.target) : root.mirror.stop(mirrorRow.target)
                    }
                }
            }
        }

        Ui.PanelButton {
            shell: root.shell
            label: "Arrange outputs…"
            onActivated: root.arrangeRequested()
        }
    }
}
