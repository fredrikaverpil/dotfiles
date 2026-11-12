import QtQuick

import "../modules/services/clipboard/ClipboardModel.js" as Model

// The clipboard service's members the view reads, without wl-paste.
QtObject {
    id: fake

    readonly property real now: new Date(2026, 10, 12, 14, 2, 7).getTime()
    // Entries as the service keeps them, newest first, `minutes` ago.
    function entry(text, minutes) {
        return {
            text: text,
            at: new Date(now - minutes * 60000)
        };
    }
    readonly property var several: [entry("https://github.com/fredrikaverpil/dotfiles/pull/245", 1), entry("nix develop . -c qml-test", 4), entry("function preview(text) {\n  return text.slice(0, 500).replace(/\\s+/g, \" \").trim();\n}", 12), entry("Thanks, that works. I'll pick it up again tomorrow morning when the new build has landed and the gallery is back up.", 47), entry("fredrik", 180), entry("192.168.1.42", 1500)]
    readonly property var many: {
        const list = [];
        for (let i = 0; i < 50; i++)
            list.push(entry("Copied line " + (i + 1) + ": " + ["git log --oneline -5", "~/.config/quickshell/kaizen", "kaizen ipc call clipboard status", "SELECT * FROM events LIMIT 10;"][i % 4], i * 9));
        return list;
    }
    readonly property var scenarios: ({
            "Several": {
                history: several
            },
            "Many": {
                history: many
            },
            "Empty": {
                history: []
            }
        })

    property var history: several

    function copy(text) {
    }

    function clear() {
        history = [];
    }

    function remove(index) {
        history = Model.removeAt(history, index);
    }
}
