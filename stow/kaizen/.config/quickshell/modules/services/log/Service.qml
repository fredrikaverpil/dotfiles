import QtQuick
import Quickshell
import Quickshell.Io

import "LogModel.js" as Model

// What `kaizen-log` lists: warnings and errors from the kaizen-* units this
// boot, earlier shell instances included.
Item {
    id: root

    // Kept for the panel; the counts cover the whole boot.
    readonly property int limit: 200
    property var entries: []
    property int count: 0
    property int errors: 0
    // Lines read since the last flush. The boot's history arrives in one burst.
    property var pending: []

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function copyAll() {
        if (entries.length === 0)
            return false;
        copy(entries.map(Model.line).join("\n"));
        return true;
    }

    function status() {
        return JSON.stringify({
            count: count,
            errors: errors,
            entries: entries
        });
    }

    // kaizen-log starts over from the boot's first entry.
    function start() {
        entries = [];
        count = 0;
        errors = 0;
        pending = [];
        reader.running = true;
    }

    Process {
        id: reader
        running: true
        command: ["kaizen-log", "--json", "--follow"]
        stdout: SplitParser {
            onRead: line => {
                const entry = Model.parse(line);
                if (!entry)
                    return;
                root.pending.push(entry);
                flush.start();
            }
        }
        onExited: restart.start()
    }

    Timer {
        id: flush
        interval: 250
        onTriggered: {
            const more = root.pending;
            root.pending = [];
            root.entries = Model.append(root.entries, more, root.limit);
            root.count += more.length;
            root.errors += more.filter(Model.isError).length;
        }
    }

    Timer {
        id: restart
        interval: 30 * 1000
        onTriggered: root.start()
    }
}
