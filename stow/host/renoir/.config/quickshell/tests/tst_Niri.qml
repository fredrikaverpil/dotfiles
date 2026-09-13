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

  function test_window_parser() {
    const raw = JSON.stringify([
      { id: 1, title: "Chat", app_id: "Slack", pid: 20, is_focused: false },
      { id: 2, title: "shell", app_id: "com.mitchellh.ghostty", pid: 10, is_focused: true },
      { id: 3, title: "xwayland", app_id: null, pid: null, is_focused: false },
    ])
    compare(Niri.parseWindows(raw), [
      { title: "shell", appId: "com.mitchellh.ghostty", pid: 10, focused: true },
      { title: "Chat", appId: "Slack", pid: 20, focused: false },
    ])
    for (const invalid of ["invalid", "", "null", "{}"]) {
      compare(Niri.parseWindows(invalid), [], invalid)
    }
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
