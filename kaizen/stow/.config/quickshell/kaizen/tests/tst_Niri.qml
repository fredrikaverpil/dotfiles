import QtQuick
import QtTest
import "../Ui/compositors/Niri.js" as Niri

TestCase {
    name: "Niri"

    function test_parse_binds_reads_titled_binds_from_the_config() {
        const raw = 'spawn-at-startup "sh" "-c" "hotkey-overlay-title=\\"x\\""\n' + 'binds {\n' + '    Mod+Space hotkey-overlay-title="Menu" { spawn "kaizen"; }\n' + '    // Mod+Q hotkey-overlay-title="Old" { quit; }\n' + '    XF86AudioMute allow-when-locked=true repeat=false hotkey-overlay-title="Mute" { spawn "kaizen"; }\n' + '    Mod+T { spawn "kitty"; }\n' + '}\n';
        compare(Niri.parseBinds(raw), [
            {
                chord: "Mod+Space",
                label: "Menu",
                enabled: true
            },
            {
                chord: "XF86AudioMute",
                label: "Mute",
                enabled: true
            },
        ]);
        compare(Niri.parseBinds(""), []);
    }

    function test_parse_binds_keeps_what_a_bind_runs_data() {
        return [
            {
                tag: "ipc",
                line: 'Mod+Print repeat=false hotkey-overlay-title="Record" { spawn "kaizen" "ipc" "call" "recording" "toggle"; }',
                want: {
                    chord: "Mod+Print",
                    label: "Record",
                    enabled: true,
                    ipc: "recording toggle"
                }
            },
            {
                tag: "ipc with an argument",
                line: 'Mod+1 hotkey-overlay-title="Zone" { spawn "kaizen" "ipc" "call" "timezone" "set" "UTC"; }',
                want: {
                    chord: "Mod+1",
                    label: "Zone",
                    enabled: true,
                    ipc: "timezone set UTC"
                }
            },
            {
                tag: "action",
                line: 'Mod+Q hotkey-overlay-title="Close window" { close-window; }',
                want: {
                    chord: "Mod+Q",
                    label: "Close window",
                    enabled: true,
                    action: "close-window"
                }
            },
            {
                tag: "action with an argument",
                line: 'Mod+1 hotkey-overlay-title="Workspace 1" { focus-workspace 1; }',
                want: {
                    chord: "Mod+1",
                    label: "Workspace 1",
                    enabled: true
                }
            },
            {
                tag: "plain spawn",
                line: 'Mod+Return hotkey-overlay-title="New terminal" { spawn "ghostty"; }',
                want: {
                    chord: "Mod+Return",
                    label: "New terminal",
                    enabled: true
                }
            },
            {
                tag: "kaizen without ipc call",
                line: 'Mod+Space hotkey-overlay-title="Menu" { spawn "kaizen"; }',
                want: {
                    chord: "Mod+Space",
                    label: "Menu",
                    enabled: true
                }
            },
            {
                tag: "spawn-sh",
                line: 'Mod+A hotkey-overlay-title="Apps" { spawn-sh "kaizen ipc call menu toggle"; }',
                want: {
                    chord: "Mod+A",
                    label: "Apps",
                    enabled: true
                }
            },
            {
                tag: "two actions",
                line: 'Mod+W hotkey-overlay-title="Both" { close-window; quit; }',
                want: {
                    chord: "Mod+W",
                    label: "Both",
                    enabled: true
                }
            },
            {
                tag: "body on later lines",
                line: 'Mod+B hotkey-overlay-title="Split"',
                want: {
                    chord: "Mod+B",
                    label: "Split",
                    enabled: true
                }
            },
        ];
    }

    function test_parse_binds_keeps_what_a_bind_runs(data) {
        const raw = `binds {\n    ${data.line}\n}\n`;

        const binds = Niri.parseBinds(raw);

        compare(binds, [data.want]);
    }

    function test_read_binds_expands_includes_in_place() {
        const bind = (chord, label) => `binds {\n    ${chord} hotkey-overlay-title="${label}" { spawn "x"; }\n}\n`;
        const files = {
            "/home/u/.config/niri/config.kdl": 'include "a.kdl"\n' + bind("Mod+A", "Main") + 'include optional=true "~/extra.kdl"\n' + 'include optional=true "missing.kdl"\n' + '// include "commented.kdl"\n',
            "/home/u/.config/niri/a.kdl": bind("Mod+B", "A") + 'include "/etc/b.kdl"\n',
            "/etc/b.kdl": bind("Mod+C", "B"),
            "/home/u/extra.kdl": bind("Mod+D", "Extra"),
            "/home/u/.config/niri/commented.kdl": bind("Mod+E", "Commented"),
            "/c/self.kdl": 'include "self.kdl"\n' + bind("Mod+L", "Loop")
        };
        const read = path => path in files ? files[path] : null;

        compare(Niri.readBinds("/home/u/.config/niri/config.kdl", "/home/u", read), [
            {
                chord: "Mod+B",
                label: "A",
                enabled: true
            },
            {
                chord: "Mod+C",
                label: "B",
                enabled: true
            },
            {
                chord: "Mod+A",
                label: "Main",
                enabled: true
            },
            {
                chord: "Mod+D",
                label: "Extra",
                enabled: true
            },
        ]);
        // niri rejects deeper nesting; a file including itself stops there too.
        compare(Niri.readBinds("/c/self.kdl", "/home/u", read), [
            {
                chord: "Mod+L",
                label: "Loop",
                enabled: true
            }
        ]);
        compare(Niri.readBinds("/missing.kdl", "/home/u", read), []);
    }

    function test_read_binds_keeps_the_last_bind_of_a_chord() {
        const files = {
            "/c/config.kdl": 'binds {\n' + '    Mod+Space hotkey-overlay-title="Menu" { spawn "kaizen"; }\n' + '    Mod+Shift+Space hotkey-overlay-title="Next layout" { spawn "kaizen" "ipc" "call" "keyboard" "next"; }\n' + '}\n' + 'include optional=true "host.kdl"\n',
            "/c/host.kdl": 'binds {\n    Shift+Mod+space hotkey-overlay-title="Mine" { close-window; }\n}\n'
        };

        const binds = Niri.readBinds("/c/config.kdl", "/home/u", path => files[path] ?? null);

        compare(binds, [
            {
                chord: "Mod+Space",
                label: "Menu",
                enabled: true
            },
            {
                chord: "Shift+Mod+space",
                label: "Mine",
                enabled: true,
                action: "close-window"
            },
        ]);
    }

    function test_config_file() {
        const env = vars => name => vars[name];
        compare(Niri.configFile("/home/u", env({})), "/home/u/.config/niri/config.kdl");
        compare(Niri.configFile("/home/u", env({
            NIRI_CONFIG: ""
        })), "/home/u/.config/niri/config.kdl");
        compare(Niri.configFile("/home/u", env({
            XDG_CONFIG_HOME: "/cfg"
        })), "/cfg/niri/config.kdl");
        compare(Niri.configFile("/home/u", env({
            NIRI_CONFIG: "/etc/niri/trial.kdl",
            XDG_CONFIG_HOME: "/cfg"
        })), "/etc/niri/trial.kdl");
    }

    function test_output_parsers() {
        const monitor = {
            name: "Virtual-1",
            width: 1280,
            height: 800,
            scale: 2
        };
        compare(Niri.focusedMonitor('{"name":"Virtual-1","modes":[{"width":1280,"height":800,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":2}}'), monitor);
        compare(Niri.focusedMonitor('{"current_mode":null,"logical":{}}'), null);
        compare(Niri.focusedMonitor('{"name":"DP-1","modes":[{"width":3840,"height":2160}],"current_mode":0,"logical":{"scale":1.5}}').scale, 1.5);
        for (const raw of ["invalid", "", "null", "{}", "[]"]) {
            compare(Niri.focusedMonitor(raw), null, raw);
        }
    }

    function test_focused_output_on() {
        compare(Niri.focusedOutputOn("DP-1"), ["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg -j focused-output', "sh", "DP-1"]);
        // Without an output there is nothing to focus, so the plain query is used.
        compare(Niri.focusedOutputOn(""), Niri.outputs());
    }

    function test_border_colours_set_the_border_from_water() {
        compare(Niri.borderColors({
            water: "#6099C0"
        }), "layout {\n    border {\n        active-color \"#6099C0\"\n    }\n}\n");
    }

    function test_focus_app_hands_the_pattern_to_kaizen_focus() {
        compare(Niri.focusApp("^slack$"), ["kaizen", "focus", "^slack$", "true"]);
    }
}
