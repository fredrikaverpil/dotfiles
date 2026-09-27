import QtQuick
import Quickshell

// The root of <dir>/Plugin.qml, for each directory in KAIZEN_PLUGINS. A plugin
// creates its own Ui.Panel and IpcHandler, as the core panels do.
Scope {
  required property var shell
  // Its launcher node is settings.<name>, which its bar button's right-click opens.
  required property string name
  // Shaped like Menu.qml's items and providers; merged in load order.
  property var menuItems: ({})
  property var providers: ({})
  // A Ui.BarButton, placed in the bar's plugin slot on every output.
  property Component barButton: null
}
