import QtQuick
import QtTest
import "../Ui/compositors/NiriPin.js" as Pin

TestCase {
    name: "NiriPin"

    readonly property var workspaces: ({
            9: {
                id: 9,
                idx: 2
            }
        })

    function test_window_id_data() {
        return [
            {
                tag: "window present",
                windows: {
                    3: {
                        id: 3,
                        app_id: "other"
                    },
                    7: {
                        id: 7,
                        app_id: "cam"
                    }
                },
                want: 7
            },
            {
                tag: "window absent",
                windows: {
                    3: {
                        id: 3,
                        app_id: "other"
                    }
                },
                want: 0
            }
        ];
    }

    function test_window_id(data) {
        verify(Pin.windowId(data.windows, "cam") === data.want);
    }

    function test_follow_data() {
        const square = {
            WindowLayoutsChanged: {
                changes: [[7,
                        {
                            window_size: [320, 320]
                        }
                    ]]
            }
        };
        const oblong = {
            WindowLayoutsChanged: {
                changes: [[7,
                        {
                            window_size: [700, 320]
                        }
                    ]]
            }
        };
        const focused = {
            WorkspaceActivated: {
                id: 9,
                focused: true
            }
        };
        return [
            {
                tag: "square window stays",
                event: square,
                id: 7,
                requested: 0,
                want: {
                    requested: 0,
                    command: null
                }
            },
            {
                tag: "oblong window is made square",
                event: oblong,
                id: 7,
                requested: 0,
                want: {
                    requested: 700,
                    command: ["niri", "msg", "action", "set-window-height", "--id", "7", "700"]
                }
            },
            {
                // A height niri refuses is asked for once, not on every event it provokes.
                tag: "refused height is not asked again",
                event: oblong,
                id: 7,
                requested: 700,
                want: {
                    requested: 700,
                    command: null
                }
            },
            {
                tag: "another window's layout",
                event: oblong,
                id: 8,
                requested: 0,
                want: {
                    requested: 0,
                    command: null
                }
            },
            {
                tag: "window follows the focused workspace",
                event: focused,
                id: 7,
                requested: 700,
                want: {
                    requested: 700,
                    command: ["niri", "msg", "action", "move-window-to-workspace", "--window-id", "7", "--focus", "false", "2"]
                }
            },
            {
                tag: "another output's workspace",
                event: {
                    WorkspaceActivated: {
                        id: 9,
                        focused: false
                    }
                },
                id: 7,
                requested: 0,
                want: {
                    requested: 0,
                    command: null
                }
            },
            {
                tag: "unknown workspace",
                event: {
                    WorkspaceActivated: {
                        id: 4,
                        focused: true
                    }
                },
                id: 7,
                requested: 0,
                want: {
                    requested: 0,
                    command: null
                }
            },
            {
                tag: "no window",
                event: focused,
                id: 0,
                requested: 0,
                want: {
                    requested: 0,
                    command: null
                }
            }
        ];
    }

    function test_follow(data) {
        compare(Pin.follow(data.event, data.id, workspaces, data.requested), data.want);
    }
}
