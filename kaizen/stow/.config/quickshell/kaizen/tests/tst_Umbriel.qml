import QtQuick
import QtTest
import "../Ui/compositors/Umbriel.js" as Umbriel

TestCase {
    name: "Umbriel"

    function test_actions_data() {
        return [
            {
                tag: "dpms on",
                got: Umbriel.dpms(true),
                want: ["umbriel", "msg", "dpms-on"]
            },
            {
                tag: "dpms off",
                got: Umbriel.dpms(false),
                want: ["umbriel", "msg", "dpms-off"]
            },
            {
                tag: "close window",
                got: Umbriel.closeWindow(),
                want: ["umbriel", "msg", "window-close"]
            },
            {
                tag: "focus workspace",
                got: Umbriel.focusWorkspace(3, "DP-1"),
                want: ["umbriel", "msg", "workspace-switch:3/DP-1"]
            },
            {
                tag: "move floating window",
                got: Umbriel.moveFloatingWindow("a1b2", -4, 20),
                want: ["umbriel", "msg", "window-move-to:top_left/-4/20/a1b2"]
            }
        ];
    }

    function test_actions(data) {
        compare(data.got, data.want);
    }

    function test_border_colours_set_the_focused_border_from_water() {
        compare(Umbriel.borderColors({
            water: "#6099C0"
        }), '[colors.border]\nfocused = "#6099C0"\n');
    }

    function test_focused_output_on() {
        compare(Umbriel.focusedOutputOn("DP-1"), ["sh", "-c", Umbriel.focusOutput + " && umbriel outputs --json", "sh", "DP-1"]);
        // Without an output there is nothing to focus, so the plain query is used.
        compare(Umbriel.focusedOutputOn(""), Umbriel.outputs());
    }

    function test_focused_monitor_data() {
        return [
            {
                tag: "focused output",
                raw: '[{"name":"eDP-1","focused":false,"scale":1,"modes":[{"width":1920,"height":1200,"current":true}]},' + '{"name":"DP-1","focused":true,"scale":1.5,"modes":[{"width":1280,"height":720,"current":false},{"width":3840,"height":2160,"current":true}]}]',
                want: {
                    name: "DP-1",
                    width: 3840,
                    height: 2160,
                    scale: 1.5
                }
            },
            {
                tag: "no current mode",
                raw: '[{"name":"DP-1","focused":true,"scale":1,"modes":[]}]',
                want: null
            },
            {
                tag: "none focused",
                raw: '[{"name":"DP-1","focused":false,"scale":1,"modes":[{"width":1,"height":1,"current":true}]}]',
                want: null
            },
            {
                tag: "invalid",
                raw: "invalid",
                want: null
            },
            {
                tag: "empty",
                raw: "",
                want: null
            },
            {
                tag: "object",
                raw: "{}",
                want: null
            }
        ];
    }

    function test_focused_monitor(data) {
        compare(Umbriel.focusedMonitor(data.raw), data.want);
    }

    function test_pin_window_follows_the_id_data() {
        const known = {
            id: "c4",
            requested: 0,
            spaces: {}
        };
        return [
            {
                tag: "window appears",
                raw: '{"event":"windows","data":[{"id":"a1","app_id":"other"},{"id":"c4","app_id":"cam"}]}',
                state: {
                    id: 0,
                    requested: 0,
                    spaces: {}
                },
                want: known
            },
            {
                tag: "window gone",
                raw: '{"event":"windows","data":[{"id":"a1","app_id":"other"}]}',
                state: known,
                want: {
                    id: 0,
                    requested: 0,
                    spaces: {}
                }
            },
            {
                tag: "other event",
                raw: '{"event":"workspaces","data":[]}',
                state: known,
                want: known
            },
            {
                tag: "invalid",
                raw: "invalid",
                state: known,
                want: known
            }
        ];
    }

    function test_pin_window_follows_the_id(data) {
        const got = Umbriel.pinWindow(data.raw, "cam", data.state);
        compare(got, data.want);
        // The rule pins and sizes the window, so nothing is ever run.
        verify(got.command === undefined);
    }

    function test_set_layout_steps_from_current_data() {
        return [
            {
                tag: "forward",
                index: 2,
                current: 0,
                steps: "2"
            },
            {
                tag: "wraps",
                index: 0,
                current: 2,
                steps: "1"
            },
            {
                tag: "unchanged",
                index: 1,
                current: 1,
                steps: "0"
            }
        ];
    }

    function test_set_layout_steps_from_current(data) {
        const command = Umbriel.setLayout(data.index, data.current, 3);
        compare(command.slice(0, 2), ["sh", "-c"]);
        compare(command.slice(3), ["sh", data.steps]);
    }

    function test_keyboard_layouts_data() {
        return [
            {
                tag: "layouts",
                raw: '{"names":["English (US)","Swedish"],"current_index":1}',
                current: 1,
                names: ["English (US)", "Swedish"]
            },
            {
                tag: "niri's field",
                raw: '{"names":[],"current_idx":1}',
                current: -1,
                names: []
            },
            {
                tag: "no keyboard",
                raw: "",
                current: -1,
                names: []
            },
            {
                tag: "invalid",
                raw: "error: no keyboard",
                current: -1,
                names: []
            }
        ];
    }

    function test_keyboard_layouts(data) {
        verify(Umbriel.currentLayout(data.raw) === data.current);
        compare(Umbriel.layoutNames(data.raw), data.names);
    }
}
