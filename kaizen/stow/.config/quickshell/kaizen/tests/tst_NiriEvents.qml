import QtQuick
import QtTest
import "../Ui/compositors/NiriEvents.js" as Events

TestCase {
    name: "NiriEvents"

    readonly property var share: ({
            stream_id: 1,
            kind: "PipeWire"
        })
    readonly property var screencopy: ({
            stream_id: 2,
            kind: "WlrScreencopy"
        })
    readonly property var paused: Object.assign({}, share, {
        is_active: false
    })
    readonly property var workspaces: ({
            42: {
                id: 42,
                idx: 1,
                output: "DP-1",
                is_active: false,
                is_focused: false
            },
            100: {
                id: 100,
                idx: 2,
                output: "DP-1",
                is_active: true,
                is_focused: true
            },
            7: {
                id: 7,
                idx: 1,
                output: "eDP-1",
                is_active: true,
                is_focused: false
            }
        })
    readonly property var terminal: ({
            id: 3,
            app_id: "ghostty",
            workspace_id: 42
        })

    function stateWith(overrides) {
        return Object.assign({
            workspaces: {},
            windows: {},
            casts: []
        }, overrides);
    }

    function test_event_result_data() {
        return [
            {
                tag: "full workspace list replaces workspaces",
                state: stateWith({
                    workspaces: workspaces
                }),
                event: {
                    WorkspacesChanged: {
                        workspaces: [
                            {
                                id: 9,
                                idx: 1,
                                output: "eDP-1"
                            }
                        ]
                    }
                },
                want: stateWith({
                    workspaces: {
                        9: {
                            id: 9,
                            idx: 1,
                            output: "eDP-1"
                        }
                    }
                })
            },
            {
                tag: "focused activation changes only its output's active workspace",
                state: stateWith({
                    workspaces: workspaces
                }),
                event: {
                    WorkspaceActivated: {
                        id: 42,
                        focused: true
                    }
                },
                want: stateWith({
                    workspaces: {
                        42: Object.assign({}, workspaces[42], {
                            is_active: true,
                            is_focused: true
                        }),
                        100: Object.assign({}, workspaces[100], {
                            is_active: false,
                            is_focused: false
                        }),
                        7: workspaces[7]
                    }
                })
            },
            {
                tag: "unfocused activation keeps focus",
                state: stateWith({
                    workspaces: workspaces
                }),
                event: {
                    WorkspaceActivated: {
                        id: 42,
                        focused: false
                    }
                },
                want: stateWith({
                    workspaces: {
                        42: Object.assign({}, workspaces[42], {
                            is_active: true
                        }),
                        100: Object.assign({}, workspaces[100], {
                            is_active: false
                        }),
                        7: workspaces[7]
                    }
                })
            },
            {
                tag: "full window list replaces windows",
                state: stateWith({
                    windows: {
                        3: terminal
                    }
                }),
                event: {
                    WindowsChanged: {
                        windows: [
                            {
                                id: 5,
                                workspace_id: 7
                            }
                        ]
                    }
                },
                want: stateWith({
                    windows: {
                        5: {
                            id: 5,
                            workspace_id: 7
                        }
                    }
                })
            },
            {
                tag: "opened window is added",
                state: stateWith(),
                event: {
                    WindowOpenedOrChanged: {
                        window: terminal
                    }
                },
                want: stateWith({
                    windows: {
                        3: terminal
                    }
                })
            },
            {
                tag: "changed window is replaced",
                state: stateWith({
                    windows: {
                        3: terminal
                    }
                }),
                event: {
                    WindowOpenedOrChanged: {
                        window: Object.assign({}, terminal, {
                            workspace_id: 7
                        })
                    }
                },
                want: stateWith({
                    windows: {
                        3: Object.assign({}, terminal, {
                            workspace_id: 7
                        })
                    }
                })
            },
            {
                tag: "closed window is removed",
                state: stateWith({
                    windows: {
                        3: terminal
                    }
                }),
                event: {
                    WindowClosed: {
                        id: 3
                    }
                },
                want: stateWith()
            },
            {
                tag: "full cast list replaces casts",
                state: stateWith({
                    casts: [screencopy]
                }),
                event: {
                    CastsChanged: {
                        casts: [share]
                    }
                },
                want: stateWith({
                    casts: [share]
                })
            },
            {
                tag: "started cast is added",
                state: stateWith({
                    casts: [screencopy]
                }),
                event: {
                    CastStartedOrChanged: {
                        cast: share
                    }
                },
                want: stateWith({
                    casts: [screencopy, share]
                })
            },
            {
                tag: "changed cast is replaced",
                state: stateWith({
                    casts: [share, screencopy]
                }),
                event: {
                    CastStartedOrChanged: {
                        cast: paused
                    }
                },
                want: stateWith({
                    casts: [screencopy, paused]
                })
            },
            {
                tag: "stopped cast is removed",
                state: stateWith({
                    casts: [share, screencopy]
                }),
                event: {
                    CastStopped: {
                        stream_id: 1
                    }
                },
                want: stateWith({
                    casts: [screencopy]
                })
            }
        ];
    }

    function test_event_result(data) {
        compare(Events.eventResult(data.state, data.event), data.want);
    }

    function test_unchanged_families_keep_their_objects() {
        const before = stateWith({
            workspaces: workspaces,
            windows: {
                3: terminal
            },
            casts: [share]
        });
        const opened = Events.eventResult(before, {
            WindowOpenedOrChanged: {
                window: terminal
            }
        });
        verify(opened.workspaces === before.workspaces);
        verify(opened.casts === before.casts);
        verify(opened.windows !== before.windows);
    }

    function test_events_without_state_keep_the_state_data() {
        return [
            {
                tag: "layout change",
                event: {
                    WindowLayoutsChanged: {
                        changes: [[3,
                                {}
                            ]]
                    }
                }
            },
            {
                tag: "focus change",
                event: {
                    WindowFocusChanged: {
                        id: 3
                    }
                }
            },
            {
                tag: "unknown workspace activated",
                event: {
                    WorkspaceActivated: {
                        id: 999,
                        focused: true
                    }
                }
            },
            {
                tag: "unknown window closed",
                event: {
                    WindowClosed: {
                        id: 999
                    }
                }
            },
            {
                tag: "no event",
                event: null
            }
        ];
    }

    function test_events_without_state_keep_the_state(data) {
        const before = stateWith({
            workspaces: workspaces,
            windows: {
                3: terminal
            }
        });
        verify(Events.eventResult(before, data.event) === before);
    }
}
