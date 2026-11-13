import QtQuick

import "../../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The panel.
    required property var audio

    // -1 is the slider, then the rows in Output, then the settings button.
    property int cursor: -1

    readonly property int cardWidth: 400

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

    // The button takes the real focus for its Enter and Space; other keys reach the view.
    function setCursor(index) {
        cursor = index;
        if (cursor === audio.sinks.length)
            settingsButton.forceActiveFocus();
        else
            root.forceActiveFocus();
    }

    function moveCursor(delta) {
        setCursor(Math.max(audio.sink ? -1 : 0, Math.min(audio.sinks.length, cursor + delta)));
    }

    // Keeps the cursor on a stop as devices come and go; the button stays the button.
    function clampCursor() {
        if (settingsButton.activeFocus)
            setCursor(audio.sinks.length);
        else if (cursor >= audio.sinks.length || (cursor < 0 && !audio.sink))
            moveCursor(0);
    }

    function activate() {
        if (cursor < 0)
            audio.toggleMute();
        else if (cursor < audio.sinks.length)
            audio.setDefault(audio.sinks[cursor]);
    }

    // The slider and device rows need one cursor; Ui.Panel's focus chain cannot express slider adjustment.
    focus: true
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape)
            root.audio.close();
        else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier))
            root.moveCursor(-1);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.text === "j")
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

    Connections {
        target: root.audio

        function onSinksChanged() {
            root.clampCursor();
        }
        function onSinkChanged() {
            root.clampCursor();
        }
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
            onStepped: direction => root.adjust(0.05 * direction)
            onHovered: root.setCursor(-1)
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
                    onHovered: root.setCursor(index)
                    onActivated: root.audio.setDefault(modelData)
                }
            }
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            id: settingsButton
            shell: root.shell
            label: "Audio settings…"
            onActivated: root.audio.openSettings()
        }
    }
}
