import QtQuick
import QtTest
import "../Ui/compositors/Niri.js" as Niri

TestCase {
  name: "Niri"

  function test_theme_edits() {
    const palette = { dim: "#403833" }
    compare(Niri.themeEdits(palette), [
      "-e", "s|^( *inactive-color ).*|\\1\"#403833\"|"
    ])
  }

  function test_keep_square() {
    const none = { id: 0, requested: 0 }
    compare(Niri.keepSquare("invalid", "cam", none), none)
    const opened = Niri.keepSquare('{"WindowOpenedOrChanged":{"window":{"id":7,"app_id":"cam"}}}', "cam", none)
    compare(opened, { id: 7, requested: 0 })
    compare(Niri.keepSquare('{"WindowOpenedOrChanged":{"window":{"id":8,"app_id":"other"}}}', "cam", opened), opened)
    const square = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[320,320]}]]}}'
    compare(Niri.keepSquare(square, "cam", opened), opened)
    const oblong = '{"WindowLayoutsChanged":{"changes":[[7,{"window_size":[700,320]}]]}}'
    const fixed = Niri.keepSquare(oblong, "cam", opened)
    compare(fixed, { id: 7, requested: 700,
      command: ["niri", "msg", "action", "set-window-height", "--id", "7", "700"] })
    // A height niri refuses is asked for once, not on every event it provokes.
    compare(Niri.keepSquare(oblong, "cam", fixed), fixed)
    compare(Niri.keepSquare('{"WindowClosed":{"id":7}}', "cam", fixed), none)
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
}
