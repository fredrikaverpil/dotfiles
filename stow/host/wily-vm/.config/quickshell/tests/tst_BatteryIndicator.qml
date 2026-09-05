// Component tests: instantiate real QML, drive properties, assert on bindings
// and signals. This is what qmltestrunner is good for, and it is available to
// any component in this tree that does not import Quickshell.

import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "BatteryIndicator"

  BatteryIndicator {
    id: indicator
  }

  SignalSpy {
    id: lowSpy
    target: indicator
    signalName: "wentLow"
  }

  function init() {
    indicator.percent = 100
    indicator.charging = false
    lowSpy.clear()
  }

  function test_bindings_data() {
    return [
      { tag: "full", percent: 100, charging: false, icon: "󰁹", text: "100%", low: false },
      { tag: "half", percent: 50, charging: false, icon: "󰁾", text: "50%", low: false },
      { tag: "flat", percent: 4, charging: false, icon: "󰂎", text: "4%", low: true },
      { tag: "charging", percent: 4, charging: true, icon: "󰂄", text: "4% ↑", low: false }
    ]
  }

  function test_bindings(data) {
    indicator.percent = data.percent
    indicator.charging = data.charging

    compare(indicator.icon, data.icon)
    compare(indicator.text, data.text)
    compare(indicator.low, data.low)
  }

  // The reason a component test earns its place over a JS test: the JS is
  // pure, but the binding graph and the signal it drives are not.
  function test_wentLow_fires_once_per_transition() {
    indicator.percent = 10
    compare(lowSpy.count, 1)

    indicator.percent = 5
    compare(lowSpy.count, 1, "still low, so no second edge")

    indicator.percent = 80
    indicator.percent = 5
    compare(lowSpy.count, 2)
  }

  function test_charging_clears_low() {
    indicator.percent = 5
    compare(indicator.low, true)

    indicator.charging = true
    compare(indicator.low, false)
  }
}
