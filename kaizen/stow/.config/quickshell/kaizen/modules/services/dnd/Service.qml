import QtQuick
import Quickshell.Io

import "../../../Ui" as Ui
import "../../../Ui/Hold.js" as Hold

// Do not disturb: a mode the shell broadcasts, for what would interrupt the
// screen to read and hold itself back. Recording and screen sharing turn it on.
Item {
    id: root

    readonly property string statePath: Ui.Paths.state + "/dnd.json"

    property bool stateLoaded: false
    property bool active: false
    // When it turned on, in ms since the epoch; 0 while off.
    property real since: 0
    // Reasons holding it on, such as a recording, and whether a hold turned it
    // on.
    property var holds: []
    property bool owned: false

    readonly property bool sharing: Ui.Compositor.casts ? Ui.Compositor.casts.sharing : false

    // Set by hand: no hold turns it off.
    function set(value) {
        owned = false;
        apply(value);
    }

    function hold(reason, on) {
        var next = Hold.hold({
            on: active,
            holds: holds,
            owned: owned
        }, reason, on);
        holds = next.holds;
        owned = next.owned;
        apply(next.on);
    }

    function apply(value) {
        if (active === !!value)
            return;
        since = value ? Date.now() : 0;
        active = !!value;
    }

    function saveState() {
        if (stateLoaded)
            stateFile.setText(JSON.stringify({
                version: 1,
                active: active,
                since: since
            }) + "\n");
    }

    function loadState(raw) {
        var saved = {};
        try {
            saved = JSON.parse(String(raw || "{}"));
        } catch (error) {
            console.warn("dnd: ignoring invalid saved state");
        }
        // A hold placed before the state loaded keeps it on, unless it was saved on.
        if (saved.active === true || !holds.length) {
            owned = false;
            since = saved.active === true ? Number(saved.since) || Date.now() : 0;
            active = saved.active === true;
        }
        stateLoaded = true;
    }

    onActiveChanged: saveState()
    onSharingChanged: hold("sharing", sharing)

    Component.onCompleted: stateFile.reload()

    FileView {
        id: stateFile
        path: root.statePath
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadState(text())
        onLoadFailed: root.loadState("")
    }

    IpcHandler {
        target: "dnd"

        function state(): string {
            return root.active ? "on" : "off";
        }

        function toggle(): string {
            root.set(!root.active);
            return state();
        }

        function set(value: string): string {
            root.set(Hold.flag(value));
            return state();
        }
    }
}
