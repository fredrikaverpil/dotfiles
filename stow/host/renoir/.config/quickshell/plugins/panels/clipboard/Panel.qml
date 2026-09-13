import QtQuick
import QtQuick.Window
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/clipboard/ClipboardModel.js" as Model

Ui.Panel {
  id: root

  required property var service

  cardHeight: 420
  keyNavigation: true

  function pick(text) {
    root.service.copy(text)
    root.close()
  }

  readonly property var focusedItem: scroller.Window.activeFocusItem
  // Map to content coordinates: Flickable coordinates are relative to its viewport.
  onFocusedItemChanged: {
    const item = focusedItem
    if (!item || !shown || item.parent !== content) return
    const top = item.mapToItem(content, 0, 0).y
    if (!isFinite(top)) return
    if (top < scroller.contentY) scroller.contentY = Math.max(0, top)
    else if (top + item.height > scroller.contentY + scroller.height)
      scroller.contentY = top + item.height - scroller.height
  }

  IpcHandler {
    target: "clipboard"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function clear(): void { root.service.clear() }
    function status(): string {
      return JSON.stringify({ entries: root.service.history.length })
    }
  }

  Text {
    color: root.shell.palette.fg
    font.family: Ui.Fonts.mono
    font.pixelSize: 18
    text: "Clipboard"
  }

  Rectangle {
    width: parent.width
    height: 1
    color: root.shell.palette.dim
  }

  Flickable {
    id: scroller
    width: parent.width
    height: parent.height - y - clearButton.height - root.contentSpacing
    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: content
      width: scroller.width
      spacing: 2

      Repeater {
        model: root.service.history

        delegate: EntryRow {}
      }

      Text {
        visible: root.service.history.length === 0
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: "Nothing copied yet"
      }
    }
  }

  Rectangle {
    id: clearButton
    width: 160
    height: 28
    radius: 4
    color: "transparent"
    border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
    border.width: 1
    activeFocusOnTab: true

    Keys.onReturnPressed: root.service.clear()
    Keys.onEnterPressed: root.service.clear()
    Keys.onSpacePressed: root.service.clear()

    Text {
      anchors.centerIn: parent
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 12
      text: "Clear history"
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.service.clear()
    }
  }

  component EntryRow: Rectangle {
    id: row

    required property var modelData

    width: parent.width
    height: 32
    radius: 4
    color: activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
    activeFocusOnTab: true

    Keys.onReturnPressed: root.pick(row.modelData.text)
    Keys.onEnterPressed: root.pick(row.modelData.text)
    Keys.onSpacePressed: root.pick(row.modelData.text)

    Text {
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.right: time.left
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.fg
      font.family: Ui.Fonts.mono
      font.pixelSize: 14
      text: Model.preview(row.modelData.text)
      elide: Text.ElideRight
    }

    Text {
      id: time
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.shell.palette.off
      font.family: Ui.Fonts.mono
      font.pixelSize: 13
      text: Qt.formatDateTime(row.modelData.at, "ddd HH:mm")
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: root.pick(row.modelData.text)
    }
  }
}
