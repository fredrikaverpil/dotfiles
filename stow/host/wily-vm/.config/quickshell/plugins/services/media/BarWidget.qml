import QtQuick

import "../../../Ui" as Ui

// The local equivalent of Omarchy's bar widget. Their movable layout makes
// room for a scrolling track label and a mouse-only popup; this fixed,
// keyboard-first bar keeps one 28px button that opens the media panel instead.
Item {
  id: root

  // This cannot be required: QML evaluates bindings before assigning required
  // properties, and BarButton would log a transient undefined shell. Null is
  // a real initial value; Loader creates the required child only after Bar.qml
  // supplies the shell.
  property var shell: null
  readonly property bool mediaVisible: shell !== null && shell.media.hasMedia

  implicitWidth: mediaVisible ? 28 : 0
  width: implicitWidth
  height: 24

  Loader {
    anchors.fill: parent
    active: root.shell !== null
    sourceComponent: buttonComponent
  }

  Component {
    id: buttonComponent

    Ui.BarButton {
      shell: root.shell
      visible: root.mediaVisible
      label: root.mediaVisible ? root.shell.media.icon : ""
      onActivated: root.shell.media.toggle()
    }
  }
}
