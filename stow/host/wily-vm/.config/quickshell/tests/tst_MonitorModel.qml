import QtQuick
import QtTest
import "../plugins/panels/monitor/Model.js" as Monitor
import "../Ui/compositors/Scale.js" as Scale

TestCase {
  name: "MonitorModel"

  function test_scale_labels_and_gtk_rounding() {
    compare(Scale.normalizeScale("1.6"), "1.6")
    compare(Scale.normalizeScale("invalid"), "")
    compare(Monitor.gdkScale(1.6), 2)
    compare(Monitor.gdkScale(0.8), 1)
    compare(Monitor.gdkScale("invalid"), 1)
  }
}
