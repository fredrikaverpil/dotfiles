import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: panel

  required property var shell
  property bool shown: false
  property bool focusPrimed: false
  property int cardWidth: 600
  property int cardHeight: 420
  readonly property int barHeight: shell ? shell.barHeight : 32

  property bool keyNavigation: false

  default property alias content: column.data
  readonly property alias contentSpacing: column.spacing

  function open() {
    if (shell && shell.registerPanel) shell.registerPanel(panel)
    if (shell && shell.claimPanel) shell.claimPanel(panel)
    shown = true
  }

  function close() { shown = false }

  function toggle() { shown ? close() : open() }

  function focusStep(forward) {
    const current = column.Window.activeFocusItem
    if (!current) {
      column.forceActiveFocus()
      return
    }
    const next = current.nextItemInFocusChain(forward)
    if (next) next.forceActiveFocus(Qt.TabFocusReason)
  }

  onShownChanged: {
    if (!shown) {
      focusPrimed = false
      focusPrimeTimer.stop()
    } else {
      focusPrimed = false
      focusPrimeTimer.restart()
      if (keyNavigation) column.forceActiveFocus()
    }
  }
  Component.onCompleted: if (shell && shell.registerPanel) shell.registerPanel(panel)

  visible: shown
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: 0
  color: "transparent"
  mask: modalMask
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown
    ? (focusPrimed && Compositor.releaseExclusiveFocus
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.Exclusive)
    : WlrKeyboardFocus.None

  Timer {
    id: focusPrimeTimer
    interval: 75
    onTriggered: if (panel.shown) panel.focusPrimed = true
  }

  data: [
    Region {
      id: modalMask
      item: modalInput

      Region {
        width: panel.width
        height: panel.barHeight
        intersection: Intersection.Subtract
      }
    },

    Item {
      id: modalInput
      anchors.fill: parent
    },

    MouseArea {
      anchors.fill: parent
      enabled: panel.shown
      onClicked: panel.close()
    },

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: panel.cardWidth
      height: panel.cardHeight
      radius: 8
      color: panel.shell.palette.bg
      border.color: panel.shell.palette.dim
      border.width: 1

      Keys.onPressed: function (event) {
        if (!panel.keyNavigation) return
        if (event.key === Qt.Key_Escape) panel.close()
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right
          || event.text === "j" || event.text === "l") panel.focusStep(true)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left
          || event.text === "k" || event.text === "h") panel.focusStep(false)
        else return
        event.accepted = true
      }

      MouseArea {
        anchors.fill: parent
      }

      Column {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        focus: panel.keyNavigation
      }
    }
  ]
}
