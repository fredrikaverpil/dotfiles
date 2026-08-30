import QtQuick
import Quickshell
import Quickshell.Wayland

// Chrome shared by every overlay panel: a full-screen transparent layer-shell
// surface that only takes the keyboard while shown, click-outside to dismiss,
// and a centred card in the palette. Children are laid out in that card.
//
// The fixed children below are assigned through `data` rather than declared as
// plain children, because the default property is aliased away to the card's
// column -- an ordinary child here would be reparented into it.
PanelWindow {
  id: panel

  required property var shell
  property bool shown: false
  property int cardWidth: 600
  property int cardHeight: 420

  default property alias content: column.data

  function open() { shown = true }
  function close() { shown = false }
  function toggle() { shown ? close() : open() }

  visible: shown
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: 0
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  data: [
    MouseArea {
      anchors.fill: parent
      onClicked: panel.close()
    },

    Rectangle {
      anchors.centerIn: parent
      width: panel.cardWidth
      height: panel.cardHeight
      radius: 8
      color: panel.shell.palette.bg
      border.color: panel.shell.palette.dim
      border.width: 1

      Column {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
      }
    }
  ]
}
