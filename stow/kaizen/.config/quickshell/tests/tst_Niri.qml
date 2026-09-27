import QtQuick
import QtTest
import "../Ui/compositors/Niri.js" as Niri

TestCase {
  name: "Niri"

  function test_parse_binds_reads_titled_binds_from_the_config() {
    const raw = 'spawn-at-startup "sh" "-c" "hotkey-overlay-title=\\"x\\""\n'
      + 'binds {\n'
      + '    Mod+Space hotkey-overlay-title="Menu" { spawn "qs"; }\n'
      + '    // Mod+Q hotkey-overlay-title="Old" { quit; }\n'
      + '    XF86AudioMute allow-when-locked=true repeat=false hotkey-overlay-title="Mute" { spawn "qs"; }\n'
      + '    Mod+T { spawn "kitty"; }\n'
      + '}\n'
    compare(Niri.parseBinds(raw), [
      { chord: "Mod+Space", label: "Menu", enabled: true },
      { chord: "XF86AudioMute", label: "Mute", enabled: true },
    ])
    compare(Niri.parseBinds(""), [])
  }

  function test_read_binds_expands_includes_in_place() {
    const bind = (chord, label) => `binds {\n    ${chord} hotkey-overlay-title="${label}" { spawn "x"; }\n}\n`
    const files = {
      "/home/u/.config/niri/config.kdl": 'include "a.kdl"\n' + bind("Mod+A", "Main")
        + 'include optional=true "~/extra.kdl"\n'
        + 'include optional=true "missing.kdl"\n'
        + '// include "commented.kdl"\n',
      "/home/u/.config/niri/a.kdl": bind("Mod+B", "A") + 'include "/etc/b.kdl"\n',
      "/etc/b.kdl": bind("Mod+C", "B"),
      "/home/u/extra.kdl": bind("Mod+D", "Extra"),
      "/home/u/.config/niri/commented.kdl": bind("Mod+E", "Commented"),
      "/c/self.kdl": 'include "self.kdl"\n' + bind("Mod+L", "Loop"),
    }
    const read = path => path in files ? files[path] : null

    compare(Niri.readBinds("/home/u/.config/niri/config.kdl", "/home/u", read), [
      { chord: "Mod+B", label: "A", enabled: true },
      { chord: "Mod+C", label: "B", enabled: true },
      { chord: "Mod+A", label: "Main", enabled: true },
      { chord: "Mod+D", label: "Extra", enabled: true },
    ])
    // niri rejects deeper nesting; a file including itself stops there too.
    compare(Niri.readBinds("/c/self.kdl", "/home/u", read), [{ chord: "Mod+L", label: "Loop", enabled: true }])
    compare(Niri.readBinds("/missing.kdl", "/home/u", read), [])
  }

  function test_read_binds_keeps_the_last_bind_of_a_chord() {
    const files = {
      "/c/config.kdl": 'binds {\n'
        + '    Mod+Space hotkey-overlay-title="Menu" { spawn "qs"; }\n'
        + '    Mod+Shift+Space hotkey-overlay-title="Next layout" { spawn "qs"; }\n'
        + '}\n'
        + 'include optional=true "host.kdl"\n',
      "/c/host.kdl": 'binds {\n    Shift+Mod+space hotkey-overlay-title="Mine" { spawn "x"; }\n}\n',
    }

    const binds = Niri.readBinds("/c/config.kdl", "/home/u", path => files[path] ?? null)

    compare(binds, [
      { chord: "Mod+Space", label: "Menu", enabled: true },
      { chord: "Shift+Mod+space", label: "Mine", enabled: true },
    ])
  }

  function test_config_file() {
    compare(Niri.configFile("/home/u", null), "/home/u/.config/niri/config.kdl")
    compare(Niri.configFile("/home/u", ""), "/home/u/.config/niri/config.kdl")
    compare(Niri.configFile("/home/u", "/etc/niri/trial.kdl"), "/etc/niri/trial.kdl")
  }

  function test_pin_window() {
    const none = { id: 0, requested: 0, spaces: ({}) }
    compare(Niri.pinWindow("invalid", "cam", none), none)
    const opened = Niri.pinWindow('{"WindowOpenedOrChanged":{"window":{"id":7,"app_id":"cam"}}}', "cam", none)
    compare(opened, { id: 7, requested: 0, spaces: ({}) })
    compare(Niri.pinWindow('{"WindowOpenedOrChanged":{"window":{"id":8,"app_id":"other"}}}', "cam", opened), opened)

    const square = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[320,320]}]]}}'
    compare(Niri.pinWindow(square, "cam", opened), opened)
    const oblong = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[700,320]}]]}}'
    const fixed = Niri.pinWindow(oblong, "cam", opened)
    compare(fixed, { id: 7, requested: 700, spaces: ({}),
      command: ["niri", "msg", "action", "set-window-height", "--id", "7", "700"] })
    // A height niri refuses is asked for once, not on every event it provokes,
    // and a state that carries a command never repeats it on the next event.
    compare(Niri.pinWindow(oblong, "cam", fixed), { id: 7, requested: 700, spaces: ({}) })
    compare(Niri.pinWindow(square, "cam", fixed).command, undefined)

    const known = Niri.pinWindow('{"WorkspacesChanged":{"workspaces":[{"id":9,"idx":2}]}}', "cam", fixed)
    compare(known, { id: 7, requested: 700, spaces: { 9: 2 } })
    compare(Niri.pinWindow('{"WorkspaceActivated":{"id":9,"focused":true}}', "cam", known).command,
      ["niri", "msg", "action", "move-window-to-workspace", "--window-id", "7", "--focus", "false", "2"])
    // Another output's workspace and an unknown one leave the window alone.
    compare(Niri.pinWindow('{"WorkspaceActivated":{"id":9,"focused":false}}', "cam", known).command, undefined)
    compare(Niri.pinWindow('{"WorkspaceActivated":{"id":4,"focused":true}}', "cam", known).command, undefined)
    compare(Niri.pinWindow('{"WorkspaceActivated":{"id":9,"focused":true}}', "cam", none).command, undefined)

    compare(Niri.pinWindow('{"WindowClosed":{"id":7}}', "cam", known), { id: 0, requested: 0, spaces: { 9: 2 } })
  }

  function test_output_parsers() {
    const monitor = { name: "Virtual-1", width: 1280, height: 800, scale: 2 }
    compare(Niri.focusedMonitor('{"name":"Virtual-1","modes":[{"width":1280,"height":800,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":2}}'), monitor)
    compare(Niri.focusedMonitor('{"current_mode":null,"logical":{}}'), null)
    compare(Niri.focusedMonitor('{"name":"DP-1","modes":[{"width":3840,"height":2160}],"current_mode":0,"logical":{"scale":1.5}}').scale, 1.5)
    for (const raw of ["invalid", "", "null", "{}", "[]"]) {
      compare(Niri.focusedMonitor(raw), null, raw)
    }
  }

  function test_focused_output_on() {
    compare(Niri.focusedOutputOn("DP-1"),
      ["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg -j focused-output', "sh", "DP-1"])
    // Without an output there is nothing to focus, so the plain query is used.
    compare(Niri.focusedOutputOn(""), Niri.outputs())
  }
}
