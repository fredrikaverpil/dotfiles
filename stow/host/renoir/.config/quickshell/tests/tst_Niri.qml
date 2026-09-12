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

  function test_output_parsers() {
    const monitor = { name: "Virtual-1", width: 1280, height: 800 }
    compare(Niri.focusedMonitor('{"name":"Virtual-1","modes":[{"width":1280,"height":800,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":2}}'), monitor)
    compare(Niri.focusedMonitor('{"current_mode":null,"logical":{}}'), null)
    for (const raw of ["invalid", "", "null", "{}", "[]"]) {
      compare(Niri.focusedMonitor(raw), null, raw)
    }
  }
}
