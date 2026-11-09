import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The panel, or the gallery's stand-in.
    required property var audio

    // -1 is the slider, else a row in Output.
    property int cursor: -1

    readonly property int cardWidth: 400
    readonly property int cardPadding: 16
    readonly property int cardHeight: implicitHeight + 2 * cardPadding
    readonly property bool keyNavigation: false

    width: parent ? parent.width : 0
    spacing: 24

    function reset() {
        cursor = -1;
        root.forceActiveFocus();
    }

    function adjust(delta) {
        if (cursor < 0)
            audio.setVolume(audio.volume + delta);
    }

    function moveCursor(delta) {
        cursor = Math.max(audio.sink ? -1 : 0, Math.min(audio.sinks.length - 1, cursor + delta));
    }

    function activate() {
        if (cursor < 0)
            audio.toggleMute();
        else
            audio.setDefault(audio.sinks[cursor]);
    }

    // The slider and device rows need one cursor; Ui.Panel's focus chain cannot express slider adjustment.
    focus: true
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape)
            root.audio.close();
        else if (event.key === Qt.Key_Down || event.text === "j")
            root.moveCursor(1);
        else if (event.key === Qt.Key_Up || event.text === "k")
            root.moveCursor(-1);
        else if (event.key === Qt.Key_Right || event.text === "l")
            root.adjust(0.05);
        else if (event.key === Qt.Key_Left || event.text === "h")
            root.adjust(-0.05);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            root.activate();
        else
            return;
        event.accepted = true;
    }

    Column {
        width: parent.width
        spacing: 16

        Ui.PanelHeader {
            shell: root.shell
            title: "Audio"
        }

        Ui.PanelSlider {
            visible: !!root.audio.sink
            shell: root.shell
            value: root.audio.volume
            valueText: Math.round(root.audio.volume * 100) + "%"
            off: root.audio.muted
            focused: root.cursor < 0
            icon: root.audio.icon
            iconColor: root.audio.muted ? root.shell.palette.rose : root.shell.palette.fg
            onMoved: value => root.audio.setVolume(value)
            onHovered: root.cursor = -1
        }
    }

    Ui.Section {
        shell: root.shell
        title: "Output"

        Column {
            width: parent.width
            spacing: 4

            Text {
                visible: root.audio.sinks.length === 0
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: "No devices"
            }

            Repeater {
                model: root.audio.sinks

                delegate: Ui.RadioRow {
                    required property var modelData
                    required property int index

                    width: root.width
                    shell: root.shell
                    label: root.audio.label(modelData)
                    chosen: modelData === root.audio.sink
                    focused: root.cursor === index
                    onHovered: root.cursor = index
                    onActivated: root.audio.setDefault(modelData)
                }
            }
        }
    }
}
