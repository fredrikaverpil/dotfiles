import QtQuick
import QtTest
import "../Ui/compositors/Niri.js" as Niri

TestCase {
  name: "KeyboardParsing"

  function test_current_index_data() {
    return [
      { tag: "niri index", text: '{"names":["English (US)","Swedish"],"current_idx":1}', want: 1 },
      { tag: "niri first", text: '{"names":["English (US)"],"current_idx":0}', want: 0 },
      { tag: "niri missing field", text: '{"names":[]}', want: -1 }
    ]
  }

  function test_current_index(data) {
    compare(Niri.currentLayout(data.text), data.want)
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
    compare(Niri.currentLayout(niri), -1)
  }
}
