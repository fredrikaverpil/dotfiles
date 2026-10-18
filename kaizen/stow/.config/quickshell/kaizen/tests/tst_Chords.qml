import QtQuick
import QtTest
import "../Ui/compositors/Chords.js" as Chords

TestCase {
    name: "Chords"

    function test_keycaps_data() {
        return [
            {
                tag: "mod",
                chord: "Mod+Shift+Space",
                want: ["Super", "Shift", "Space"]
            },
            {
                tag: "super as written",
                chord: "Super+Alt+L",
                want: ["Super", "Alt", "L"]
            },
            {
                tag: "audio key",
                chord: "XF86AudioMicMute",
                want: ["MicMute"]
            },
            {
                tag: "monitor key",
                chord: "XF86MonBrightnessUp",
                want: ["BrightnessUp"]
            },
            {
                tag: "other xf86 key",
                chord: "XF86Calculator",
                want: ["Calculator"]
            },
            {
                tag: "plain",
                chord: "Ctrl+Alt+Delete",
                want: ["Ctrl", "Alt", "Delete"]
            },
            {
                tag: "empty",
                chord: "",
                want: []
            },
        ];
    }

    function test_keycaps(data) {
        const keys = Chords.keycaps(data.chord);

        compare(keys, data.want);
    }
}
