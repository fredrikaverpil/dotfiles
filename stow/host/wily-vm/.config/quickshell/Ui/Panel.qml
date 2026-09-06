import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland

// Chrome shared by every overlay panel: a full-screen layer-shell surface,
// click-outside to dismiss, and a centred card children are laid out in. The
// top-bar strip stays click-through so its buttons work while a panel is open.
//
// The fixed children below go through `data` rather than being declared as
// plain children: the default property is aliased to the card's column, so an
// ordinary child would be reparented into it.
PanelWindow {
  id: panel

  required property var shell
  property bool shown: false
  property bool focusPrimed: false
  property int cardWidth: 600
  property int cardHeight: 420
  readonly property int barHeight: shell ? shell.barHeight : 32

  // A panel that opts in marks its buttons `activeFocusOnTab` and highlights
  // them on `activeFocus`; Qt's focus chain does the walking, so no panel
  // keeps a cursor of its own.
  property bool keyNavigation: false

  default property alias content: column.data

  function open() {
    if (shell && shell.registerPanel) shell.registerPanel(panel)
    if (shell && shell.claimPanel) shell.claimPanel(panel)
    shown = true
  }

  function close() { shown = false }

  function toggle() { shown ? close() : open() }

  // One linear chain in document order, so the last option of a row leads into
  // the first of the next.
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
      // Start every open from the top of the chain.
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
  // Exclusive reliably acquires focus on open. On Hyprland it must then settle
  // on OnDemand, or the compositor routes pointer input here despite the
  // bar-strip cutout and the bar stops responding. Demoting on niri instead
  // hands the keyboard back to the window underneath.
  WlrLayershell.keyboardFocus: shown
    ? (focusPrimed && !Compositor.niri
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

      // Keys bubble up from whichever button holds focus.
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

      // Keeps clicks in unused card space off the dismissal area behind it;
      // interactive content stacks above.
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
