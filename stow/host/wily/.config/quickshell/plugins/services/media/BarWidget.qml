import QtQuick

import "../../../Ui" as Ui

Item {
  id: root

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
