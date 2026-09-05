import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "../../bar/widgets/TrayModel.js" as TrayModel

// A tray item's own menu. The app owns every row -- the label, the nesting,
// what a click does -- and we own only how it is drawn, so this file is all
// presentation over a QsMenuOpener.
//
// The rows are drawn here rather than through QsMenuEntry.display(), which
// renders a *platform* menu and is refused unless the shell root sets
// `//@ pragma UseQApplication`. shell.qml does not, so display() is a silent
// no-op ("Cannot display PlatformMenuEntry as quickshell was not started in
// QApplication mode" in the log) and an app whose whole UI is submenus would
// be unusable. Drawing them also means they get the palette and the panel's
// keyboard chain for free.
Ui.Panel {
  id: root

  property var item: null
  // One live opener per level: a child entry is owned by its parent opener's
  // children model, so collapsing the stack to a single opener would destroy
  // the very entry being displayed and the submenu would come up empty.
  property var stack: []

  readonly property int depth: stack.length
  readonly property var currentChildren: depth > 0
    ? stack[depth - 1].opener.children
    : null
  readonly property string title: item
    ? (depth > 0
      ? stack.map(level => level.title).join(" › ")
      : (item.title || item.tooltipTitle || item.id))
    : ""

  cardWidth: 420
  cardHeight: 380
  keyNavigation: true

  // The bar icon is a mouse-only affordance, so the menu needs a way in that
  // is not a right click -- the launcher's Tray level calls the same path.
  IpcHandler {
    target: "tray"

    function menu(id: string): void {
      const found = SystemTray.items.values.find(item => String(item.id) === id)
      if (found) root.openFor(found)
    }
    function list(): string {
      return TrayModel.sortItems(SystemTray.items.values)
        .map(item => item.id + "\t" + TrayModel.labelFor(item)).join("\n")
    }
    function close(): void { root.close() }
  }

  Component {
    id: openerComponent
    QsMenuOpener {}
  }

  function push(handle, title) {
    const opener = openerComponent.createObject(root, { menu: handle })
    if (!opener) return
    stack = stack.concat([{ opener: opener, title: title }])
    settle()
  }

  function pop() {
    if (stack.length <= 1) { close(); return }
    const levels = stack.slice()
    const top = levels.pop()
    stack = levels
    top.opener.destroy()
    settle()
  }

  function reset() {
    settling = false
    settleTimer.stop()
    // Clear the reactive stack before tearing anything down, so no binding can
    // read a partially-destroyed opener while this runs. Then destroy deepest
    // first: an inner opener's menu entry is owned by its parent's children
    // model, so destroying a parent first would invalidate an entry a still-
    // live child opener references.
    const levels = stack
    stack = []
    for (let i = levels.length - 1; i >= 0; i--) levels[i].opener.destroy()
  }

  function openFor(trayItem) {
    // Reset before switching items: the root opener binds to the item's menu,
    // so assigning a new item invalidates the old root's children immediately.
    reset()
    item = trayItem
    if (!trayItem || !trayItem.hasMenu) return
    push(trayItem.menu, trayItem.title || trayItem.id)
    open()
  }

  // Changing level rebuilds the row delegates synchronously, so the next row
  // lands under a cursor that has not moved. Ignore row clicks for a beat
  // after each level change; a deliberate follow-up click is slower.
  property bool settling: false

  function settle() {
    settling = true
    settleTimer.restart()
  }

  Timer {
    id: settleTimer
    interval: 250
    onTriggered: root.settling = false
  }

  onShownChanged: if (!shown) reset()

  Text {
    color: root.shell.palette.dim
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    text: root.title
    width: parent.width
    elide: Text.ElideRight
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Flickable {
    width: parent.width
    height: parent.height - y
    clip: true
    contentHeight: rows.height
    // Backing out of a level is Escape at the root, so Left is the only key
    // that means "up one" everywhere. Panel.qml already spends Left on focus
    // stepping, so this handler sits above it and takes Backspace instead.
    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Backspace) {
        root.pop()
        event.accepted = true
      }
    }

    Column {
      id: rows
      width: parent.width
      spacing: 2

      Repeater {
        model: root.currentChildren

        Rectangle {
          id: row

          required property var modelData

          width: rows.width
          height: modelData.isSeparator ? 9 : 28
          radius: 4
          color: "transparent"
          border.color: row.activeFocus ? root.shell.palette.fg : "transparent"
          border.width: 1
          opacity: modelData.enabled ? 1 : 0.45

          // A separator is not a stop on the way to anything.
          activeFocusOnTab: !modelData.isSeparator

          function trigger() {
            if (!modelData.enabled || root.settling) return
            if (modelData.hasChildren) {
              root.push(modelData, modelData.text || "")
              return
            }
            modelData.triggered()
            root.close()
          }

          Keys.onReturnPressed: row.trigger()
          Keys.onEnterPressed: row.trigger()
          Keys.onSpacePressed: row.trigger()

          Rectangle {
            visible: row.modelData.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 16
            x: 8
            height: 1
            color: root.shell.palette.dim
          }

          Row {
            visible: !row.modelData.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 8

            // The app says whether a row is a checkbox or a radio; we decide
            // what one looks like. Qt.Checked is 2, PartiallyChecked 1.
            Text {
              width: 14
              color: root.shell.palette.fg
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 14
              text: row.modelData.buttonType === QsMenuButtonType.CheckBox
                ? (row.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱")
                : row.modelData.buttonType === QsMenuButtonType.RadioButton
                  ? (row.modelData.checkState === Qt.Checked ? "󰐾" : "󰄴")
                  : ""
            }

            Text {
              color: root.shell.palette.fg
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 14
              text: (row.modelData.text || "") + (row.modelData.hasChildren ? " ›" : "")
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !row.modelData.isSeparator
            hoverEnabled: true
            onEntered: if (row.activeFocusOnTab) row.forceActiveFocus()
            onClicked: row.trigger()
          }
        }
      }
    }
  }
}
