import QtQuick
import QtTest
import "../plugins/services/brightness/BrightnessModel.js" as Brightness

TestCase {
  name: "BrightnessModel"

  function test_percent_data() {
    return [
      { tag: "full", raw: 64764, max: 64764, want: 100 },
      { tag: "half", raw: 32382, max: 64764, want: 50 },
      { tag: "rounds", raw: 64265, max: 64764, want: 99 },
      { tag: "above max", raw: 70000, max: 64764, want: 100 },
      { tag: "no device", raw: 0, max: 0, want: 0 },
    ]
  }

  function test_percent(data) {
    verify(Brightness.percent(data.raw, data.max) === data.want)
  }

  function test_raw_for_data() {
    return [
      { tag: "half", value: 50, max: 64764, want: 32382 },
      { tag: "clamps high", value: 105, max: 64764, want: 64764 },
      { tag: "floors at 1%", value: -5, max: 64764, want: 648 },
      { tag: "floors at 1 step", value: 0, max: 10, want: 1 },
    ]
  }

  function test_raw_for(data) {
    verify(Brightness.rawFor(data.value, data.max) === data.want)
  }
}
