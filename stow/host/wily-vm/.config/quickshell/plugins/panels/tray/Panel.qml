import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../../../Ui" as Ui
import "../../bar/widgets/TrayModel.js" as TrayModel

// A tray item's own menu: presentation over a QsMenuOpener, since the app owns
// every row.
//
// Drawn here rather than through QsMenuEntry.display(), which renders a
// platform menu and is a silent no-op unless the shell root sets
// `//@ pragma UseQApplication`. Drawing them also gets the palette and the
// panel's keyboard chain for free.
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
      : TrayModel.labelFor(item))
    : ""

  cardWidth: 420
  cardHeight: 380
  keyNavigation: true

  // The launcher's Tray level calls this too, since the bar icon's right click
  // is mouse-only.
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
    // Clear the reactive stack first, so no binding reads a half-destroyed
    // opener. Then destroy deepest first: a parent's children model owns the
    // inner opener's entry.
    const levels = stack
    stack = []
    for (let i = levels.length - 1; i >= 0; i--) levels[i].opener.destroy()
  }

  function openFor(trayItem) {
    // Clicking the icon whose menu is already showing closes it, like every
    // other bar button. onShownChanged tears the stack down.
    if (shown && item === trayItem) {
      close()
      return
    }
    // The root opener binds to the item's menu, so assigning a new item
    // invalidates the old root's children immediately.
    reset()
    item = trayItem
    if (!trayItem || !trayItem.hasMenu) return
    push(trayItem.menu, TrayModel.labelFor(trayItem))
    open()
  }

  // Changing level rebuilds the delegates synchronously, so the next row lands
  // under a cursor that has not moved. Ignore clicks for a beat.
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
    // Panel.qml already spends Left on focus stepping, so this handler sits
    // above it and takes Backspace too.
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

            // The app says checkbox or radio; the look is ours. Qt.Checked is
            // 2, PartiallyChecked 1.
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
