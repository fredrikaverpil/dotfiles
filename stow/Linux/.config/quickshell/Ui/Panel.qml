import QtQuick
import Quickshell
import Quickshell.Wayland

// Chrome shared by every overlay panel: a full-screen transparent layer-shell
// surface that only takes the keyboard while shown, click-outside to dismiss,
// and a centred card in the palette. The top-bar strip is click-through, so
// its buttons can toggle or switch panels even while one is open. Children are
// laid out in that card.
//
// The fixed children below are assigned through `data` rather than declared as
// plain children, because the default property is aliased away to the card's
// column -- an ordinary child here would be reparented into it.
PanelWindow {
  id: panel

  required property var shell
  property bool shown: false
  property bool pinnable: false
  property bool pinned: false
  property bool focusPrimed: false
  property int cardWidth: 600
  property int cardHeight: 420
  readonly property int barHeight: shell ? shell.barHeight : 32

  default property alias content: column.data

  function open() {
    if (shell && shell.registerPanel) shell.registerPanel(panel)
    if (shell && shell.claimPanel) shell.claimPanel(panel)
    shown = true
  }

  // A pin is intentionally the only control that can unpin or close a pinned
  // panel. Its bar button and outside clicks leave it in place.
  function close() {
    if (!pinned) shown = false
  }

  function toggle() { shown ? close() : open() }

  function togglePinned() {
    if (!pinnable) return
    pinned = !pinned
    if (pinned) open()
  }

  onPinnableChanged: if (!pinnable) pinned = false
  onShownChanged: {
    if (!shown) {
      pinned = false
      focusPrimed = false
      focusPrimeTimer.stop()
    } else if (!pinned) {
      focusPrimed = false
      focusPrimeTimer.restart()
    }
  }
  onPinnedChanged: {
    if (pinned) {
      focusPrimed = false
      focusPrimeTimer.stop()
    } else if (shown) {
      focusPrimed = false
      focusPrimeTimer.restart()
    }
  }
  Component.onCompleted: if (shell && shell.registerPanel) shell.registerPanel(panel)

  visible: shown
  anchors { top: true; bottom: true; left: true; right: true }
  exclusiveZone: 0
  color: "transparent"
  // The modal surface owns the screen except the bar. A pinned surface only
  // owns its card, leaving ordinary apps and the bar fully interactive.
  mask: panel.pinned ? pinnedMask : modalMask
  WlrLayershell.layer: WlrLayer.Overlay
  // Exclusive reliably acquires focus on every open. Settle on OnDemand as
  // soon as it has mapped so the compositor can route pointer input through
  // the bar-strip cutout to the bar below.
  WlrLayershell.keyboardFocus: shown && !pinned
    ? (focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)
    : WlrKeyboardFocus.None

  Timer {
    id: focusPrimeTimer
    interval: 75
    onTriggered: if (panel.shown && !panel.pinned) panel.focusPrimed = true
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

    Region {
      id: pinnedMask
      item: card
    },

    Item {
      id: modalInput
      anchors.fill: parent
    },

    MouseArea {
      anchors.fill: parent
      enabled: panel.shown && !panel.pinned
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

      // Prevent clicks in unused card space from reaching the modal dismissal
      // area behind it. Interactive content is stacked above this catcher.
      MouseArea {
        anchors.fill: parent
      }

      Column {
        id: column
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        anchors.rightMargin: panel.pinnable ? pinControl.width + 20 : 12
        spacing: 8
      }

      Rectangle {
        id: pinControl
        visible: panel.pinnable
        z: 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        width: pinLabel.implicitWidth + 14
        height: 24
        radius: 4
        color: pinMouse.containsMouse ? panel.shell.palette.sel : "transparent"
        border.color: panel.shell.palette.dim
        border.width: 1

        Text {
          id: pinLabel
          anchors.centerIn: parent
          text: panel.pinned ? "Unpin" : "Pin"
          color: panel.shell.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
        }

        MouseArea {
          id: pinMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: panel.togglePinned()
        }
      }
    }
  ]
}
