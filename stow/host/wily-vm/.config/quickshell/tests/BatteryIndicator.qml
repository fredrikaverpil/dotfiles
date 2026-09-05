// Dummy subject for tst_BatteryIndicator.qml.
//
// Deliberately imports nothing from Quickshell: that is the entire condition
// for being testable under qmltestrunner. It reads the same BatteryModel.js the
// shell would, so the JS tests and the QML tests cover one implementation.

import QtQuick
import "BatteryModel.js" as BatteryModel

Item {
  id: root

  property real percent: 0
  property bool charging: false

  readonly property string icon: BatteryModel.iconFor(root.percent, root.charging)
  readonly property string text: BatteryModel.label(root.percent, root.charging)
  readonly property bool low: BatteryModel.isLow(root.percent, root.charging)

  signal wentLow

  onLowChanged: if (root.low) root.wentLow()
}
