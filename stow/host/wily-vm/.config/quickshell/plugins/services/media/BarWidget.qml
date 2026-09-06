import QtQuick

import "../../../Ui" as Ui

// One 28px button that opens the media panel.
Item {
  id: root

  // Not `required`: QML evaluates bindings before assigning required
  // properties, so BarButton would log a transient undefined shell. The Loader
  // creates it only once Bar.qml has supplied one.
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
