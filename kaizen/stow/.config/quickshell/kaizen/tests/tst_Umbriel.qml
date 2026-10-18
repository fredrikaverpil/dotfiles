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

    function test_parse_binds_reads_labelled_binds_from_keybinds() {
        const raw = '"Mod+A" = "window-close" # Outside\n' + '[keybinds]\n' + '# "Mod+B" = "window-close" # Commented\n' + '"Mod+Space" = "spawn:kaizen ipc call menu toggle" # Menu\n' + '"XF86AudioMute" = { action = "spawn:kaizen ipc call audio mute", allow_when_locked = true, repeat = false } # Mute\n' + '"Mod+T" = "spawn:kitty"\n' + '"submap[resize],H" = "window-resize-left" # In a submap\n' + '[[window_rule]]\n' + '"Mod+C" = "window-close" # Not a bind\n';

        const binds = Umbriel.parseBinds(raw);

        compare(binds, [
            {
                chord: "Mod+Space",
                label: "Menu",
                enabled: true,
                ipc: "menu toggle"
            },
            {
                chord: "XF86AudioMute",
                label: "Mute",
                enabled: true,
                ipc: "audio mute"
            },
        ]);
        compare(Umbriel.parseBinds(""), []);
    }

    function test_parse_binds_keeps_what_a_bind_runs_data() {
        return [
            {
                tag: "action",
                line: '"Mod+Q" = "window-close" # Close window',
                want: {
                    chord: "Mod+Q",
                    label: "Close window",
                    enabled: true,
                    action: "window-close"
                }
            },
            {
                tag: "action with an argument",
                line: '"Mod+1" = "workspace-switch:1" # Workspace 1',
                want: {
                    chord: "Mod+1",
                    label: "Workspace 1",
                    enabled: true
                }
            },
            {
                tag: "ipc in a table, after other keys",
                line: "\"Print\" = { repeat = false, action = 'spawn:kaizen ipc call recording shoot screen' } # Shoot",
                want: {
                    chord: "Print",
                    label: "Shoot",
                    enabled: true,
                    ipc: "recording shoot screen"
                }
            },
            {
                tag: "spawn with an escaped regex",
                line: '"Mod+T" = "spawn:kaizen focus \'^com\\\\.mitchellh\\\\.ghostty$\' ghostty" # Terminal',
                want: {
                    chord: "Mod+T",
                    label: "Terminal",
                    enabled: true
                }
            },
            {
                tag: "a hash inside the value",
                line: '"Mod+H" = "spawn:notify-send \'#1\'" # Hash',
                want: {
                    chord: "Mod+H",
                    label: "Hash",
                    enabled: true
                }
            },
            {
                tag: "bare key",
                line: 'XF86AudioPlay = "spawn:kaizen ipc call media playPause" # Play',
                want: {
                    chord: "XF86AudioPlay",
                    label: "Play",
                    enabled: true,
                    ipc: "media playPause"
                }
            },
        ];
    }

    function test_parse_binds_keeps_what_a_bind_runs(data) {
        compare(Umbriel.parseBinds("[keybinds]\n" + data.line + "\n"), [data.want]);
    }

    function test_read_binds_follows_umbriels_merge_order() {
        const bind = (chord, label) => '[keybinds]\n"' + chord + '" = "window-close" # ' + label + '\n';
        const files = {
            "/home/u/.config/umbriel/config.toml": '[include]\nfiles = [\n  "a.toml", # first\n  "/etc/b.toml",\n]\n\n' + '[include.optional]\nfiles = ["~/extra.toml", "missing.toml"]\n\n' + bind("Mod+A", "Main"),
            "/home/u/.config/umbriel/a.toml": '[include]\nfiles = ["config.toml"]\n' + bind("Mod+B", "A"),
            "/etc/b.toml": bind("Mod+C", "B"),
            "/home/u/extra.toml": bind("Mod+D", "Extra")
        };
        const read = path => path in files ? files[path] : null;

        const binds = Umbriel.readBinds("/home/u/.config/umbriel/config.toml", "/home/u", read);

        // Includes come before the including file's own binds; a.toml's
        // include of config.toml is a cycle umbriel skips.
        compare(binds.map(bind => bind.label), ["A", "B", "Extra", "Main"]);
        compare(Umbriel.readBinds("/missing.toml", "/home/u", read), []);
    }

    function test_read_binds_keeps_the_last_bind_of_a_chord() {
        const files = {
            "/c/config.toml": '[include]\nfiles = ["kaizen.toml"]\n[keybinds]\n"Shift+Mod+space" = "window-close" # Mine\n',
            "/c/kaizen.toml": '[keybinds]\n"Mod+Space" = "spawn:kaizen ipc call menu toggle" # Menu\n"Mod+Shift+Space" = "spawn:kaizen ipc call keyboard next" # Next layout\n'
        };

        const binds = Umbriel.readBinds("/c/config.toml", "/home/u", path => files[path] ?? null);

        compare(binds, [
            {
                chord: "Mod+Space",
                label: "Menu",
                enabled: true,
                ipc: "menu toggle"
            },
            {
                chord: "Shift+Mod+space",
                label: "Mine",
                enabled: true,
                action: "window-close"
            },
        ]);
    }

    function test_config_file() {
        const env = vars => name => vars[name];
        compare(Umbriel.configFile("/home/u", env({})), "/home/u/.config/umbriel/config.toml");
        compare(Umbriel.configFile("/home/u", env({
            XDG_CONFIG_HOME: "/cfg"
        })), "/cfg/umbriel/config.toml");
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
