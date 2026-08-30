import QtQuick
import QtQuick.Window
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

  // Opt-in keyboard navigation. A panel that sets this marks its buttons
  // `activeFocusOnTab` and highlights them on `activeFocus`; Qt's own focus
  // chain then does the walking, so no panel keeps a cursor of its own. Off
  // for the menu, which drives its list from its search field instead.
  property bool keyNavigation: false

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

  // One linear chain in document order, so the last option of a row leads into
  // the first of the next. h/k step back, l/j step forward.
  function focusStep(forward) {
    // Via the Window attached property rather than the window object: this is
    // plain QtQuick and does not depend on what PanelWindow chooses to expose.
    const current = column.Window.activeFocusItem
    if (!current) {
      column.forceActiveFocus()
      return
    }
    const next = current.nextItemInFocusChain(forward)
    if (next) next.forceActiveFocus(Qt.TabFocusReason)
  }

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
      // Start every open from the top of the chain rather than wherever the
      // last visit left it.
      if (keyNavigation) column.forceActiveFocus()
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

      // Keys bubble up from whichever control holds focus, so the handler sits
      // on the card: their only common ancestor, since the pin control is a
      // sibling of the content column rather than inside it.
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

        focus: panel.keyNavigation
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
        border.color: pinControl.activeFocus ? panel.shell.palette.fg : panel.shell.palette.dim
        border.width: 1

        activeFocusOnTab: panel.keyNavigation && panel.pinnable
        Keys.onReturnPressed: panel.togglePinned()
        Keys.onEnterPressed: panel.togglePinned()
        Keys.onSpacePressed: panel.togglePinned()

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
