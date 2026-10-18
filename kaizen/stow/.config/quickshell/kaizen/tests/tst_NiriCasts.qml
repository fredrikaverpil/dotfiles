import QtQuick
import QtTest
import "../Ui/compositors/NiriCasts.js" as Casts

TestCase {
    name: "NiriCasts"

    readonly property var share: ({
            stream_id: 1,
            session_id: 1,
            kind: "PipeWire",
            target: {
                Output: {
                    name: "eDP-1"
                }
            },
            is_dynamic_target: false,
            is_active: true,
            pid: null,
            pw_node_id: 60
        })
    readonly property var screencopy: ({
            stream_id: 2,
            session_id: 2,
            kind: "WlrScreencopy",
            target: {
                Output: {
                    name: "eDP-1"
                }
            },
            is_dynamic_target: false,
            is_active: true,
            pid: 1234,
            pw_node_id: null
        })
    readonly property var paused: Object.assign({}, share, {
        is_active: false
    })

    function test_sharing_data() {
        return [
            {
                tag: "no casts",
                casts: [],
                want: false
            },
            {
                tag: "portal share",
                casts: [share],
                want: true
            },
            {
                tag: "paused portal share",
                casts: [paused],
                want: true
            },
            {
                tag: "screencopy only",
                casts: [screencopy],
                want: false
            }
        ];
    }

    function test_sharing(data) {
        verify(Casts.sharing(data.casts) === data.want);
    }
}
