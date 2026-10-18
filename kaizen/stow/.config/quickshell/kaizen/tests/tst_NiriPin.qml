import QtQuick
import QtTest
import "../Ui/compositors/NiriPin.js" as Pin

TestCase {
    name: "NiriPin"

    function test_pin_window() {
        const none = {
            id: 0,
            requested: 0,
            spaces: ({})
        };
        compare(Pin.follow("invalid", "cam", none), none);
        const opened = Pin.follow('{"WindowOpenedOrChanged":{"window":{"id":7,"app_id":"cam"}}}', "cam", none);
        compare(opened, {
            id: 7,
            requested: 0,
            spaces: ({})
        });
        compare(Pin.follow('{"WindowOpenedOrChanged":{"window":{"id":8,"app_id":"other"}}}', "cam", opened), opened);

        const square = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[320,320]}]]}}';
        compare(Pin.follow(square, "cam", opened), opened);
        const oblong = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[700,320]}]]}}';
        const fixed = Pin.follow(oblong, "cam", opened);
        compare(fixed, {
            id: 7,
            requested: 700,
            spaces: ({}),
            command: ["niri", "msg", "action", "set-window-height", "--id", "7", "700"]
        });
        // A height niri refuses is asked for once, not on every event it provokes,
        // and a state that carries a command never repeats it on the next event.
        compare(Pin.follow(oblong, "cam", fixed), {
            id: 7,
            requested: 700,
            spaces: ({})
        });
        compare(Pin.follow(square, "cam", fixed).command, undefined);

        const known = Pin.follow('{"WorkspacesChanged":{"workspaces":[{"id":9,"idx":2}]}}', "cam", fixed);
        compare(known, {
            id: 7,
            requested: 700,
            spaces: {
                9: 2
            }
        });
        compare(Pin.follow('{"WorkspaceActivated":{"id":9,"focused":true}}', "cam", known).command, ["niri", "msg", "action", "move-window-to-workspace", "--window-id", "7", "--focus", "false", "2"]);
        // Another output's workspace and an unknown one leave the window alone.
        compare(Pin.follow('{"WorkspaceActivated":{"id":9,"focused":false}}', "cam", known).command, undefined);
        compare(Pin.follow('{"WorkspaceActivated":{"id":4,"focused":true}}', "cam", known).command, undefined);
        compare(Pin.follow('{"WorkspaceActivated":{"id":9,"focused":true}}', "cam", none).command, undefined);

        compare(Pin.follow('{"WindowClosed":{"id":7}}', "cam", known), {
            id: 0,
            requested: 0,
            spaces: {
                9: 2
            }
        });
    }
}
