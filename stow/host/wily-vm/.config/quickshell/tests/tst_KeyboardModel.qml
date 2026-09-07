import QtQuick
import QtTest
import "../Ui/compositors/Hyprland.js" as Hyprland
import "../Ui/compositors/Niri.js" as Niri

TestCase {
  name: "KeyboardParsing"

  function test_current_index_data() {
    return [
      { tag: "niri index", backend: "niri", text: '{"names":["English (US)","Swedish"],"current_idx":1}', want: 1 },
      { tag: "niri first", backend: "niri", text: '{"names":["English (US)"],"current_idx":0}', want: 0 },
      { tag: "niri missing field", backend: "niri", text: '{"names":[]}', want: -1 },
      { tag: "hypr main keyboard", backend: "hyprland", text: '{"keyboards":[{"name":"power-button","active_layout_index":0},{"name":"at-translated-set-2","main":true,"active_layout_index":1}]}', want: 1 },
      { tag: "hypr first keyboard", backend: "hyprland", text: '{"keyboards":[{"name":"at-translated-set-2","active_layout_index":1}]}', want: 1 },
      { tag: "hypr empty", backend: "hyprland", text: '{"keyboards":[]}', want: -1 },
      { tag: "hypr missing field", backend: "hyprland", text: '{"keyboards":[{"main":true}]}', want: -1 }
    ]
  }

  function test_current_index(data) {
    compare((data.backend === "niri" ? Niri : Hyprland).currentLayout(data.text), data.want)
  }

  function test_invalid_output_data() {
    return [
      { tag: "empty", text: "" },
      { tag: "error", text: "compositor: not running" },
      { tag: "array", text: "[]" },
      { tag: "null", text: "null" },
      { tag: "null index", value: null },
      { tag: "string index", value: "1" },
      { tag: "negative index", value: -1 },
      { tag: "fractional index", value: 0.5 }
    ]
  }

  function test_invalid_output(data) {
    const niri = data.text === undefined ? JSON.stringify({ current_idx: data.value }) : data.text
    const hyprland = data.text === undefined ? JSON.stringify({ keyboards: [{ active_layout_index: data.value }] }) : data.text
    compare(Niri.currentLayout(niri), -1)
    compare(Hyprland.currentLayout(hyprland), -1)
  }
}
