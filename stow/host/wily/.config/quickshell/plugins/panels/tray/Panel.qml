import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland

import "../../../Ui" as Ui
import "../../bar/widgets/TrayModel.js" as TrayModel

// Cascading tray menu. Not a Ui.Panel: its card is centered and its h/l step focus,
// while here cards follow the tray button and h/l close and open submenus.
PanelWindow {
  id: root

  required property var shell
  property bool shown: false

  property var item: null
  // One level per open card: { opener, source, anchor }.
  property var stack: []
  // Selected row per level; -1 until one is picked, -2 for the first selectable row.
  property var cursor: []
  // Bar Tray widgets, one per output.
  property var trays: []

  readonly property int depth: stack.length

  function close() { shown = false }

  function registerTray(tray) {
    if (trays.indexOf(tray) < 0) trays = trays.concat([tray])
  }

  function unregisterTray(tray) {
    trays = trays.filter(candidate => candidate !== tray)
  }

  function rowsAt(level) {
    return cards.itemAt(level)?.rows ?? [] // qmllint disable missing-property
  }

  // The item's primary action heads its root menu, so the menu reaches everything.
  function rowsFor(opener, level) {
    const entries = opener && opener.children ? opener.children.values : []
    if (level !== 0 || !item || item.onlyMenu) return entries
    return [
      { text: "Activate", enabled: true, isSeparator: false, triggered: () => root.item.activate() },
      { isSeparator: true, enabled: true },
    ].concat(entries)
  }

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

  // Child entries belong to their parent opener, so every menu level needs its own opener.
  Component {
    id: openerComponent
    QsMenuOpener {}
  }

  function push(handle, anchor, selectFirst) {
    const opener = openerComponent.createObject(root, { menu: handle })
    if (!opener) return
    cursor = cursor.slice(0, depth).concat([selectFirst ? -2 : -1])
    stack = stack.concat([{ opener: opener, source: handle, anchor: anchor }])
    levels.append({})
    settle()
  }

  // Close every card deeper than level.
  function truncate(level) {
    if (depth <= level) return
    // Clear bindings before destroying openers, deepest first.
    const removed = stack.slice(level)
    stack = stack.slice(0, level)
    cursor = cursor.slice(0, level)
    levels.remove(level, removed.length)
    for (let i = removed.length - 1; i >= 0; i--) removed[i].opener.destroy()
  }

  function pop() {
    if (depth <= 1) close()
    else truncate(depth - 1)
  }

  function reset() {
    settling = false
    settleTimer.stop()
    hoverTimer.stop()
    truncate(0)
  }

  function select(level, index) {
    const next = cursor.slice()
    next[level] = index
    cursor = next
  }

  // output is the bar's screen name; without one the menu opens on the focused output.
  function openFor(trayItem, output) {
    if (shown && item === trayItem) {
      close()
      return
    }
    if (!trayItem || !trayItem.hasMenu) return
    if (!output) {
      pendingItem = trayItem
      focusedOutput.running = true
      return
    }
    shown = false
    reset()
    pointer = Qt.point(-1, -1)
    item = trayItem
    screen = Quickshell.screens.find(candidate => candidate.name === output) || null
    const tray = trays.find(candidate => candidate.output === output)
    const button = tray ? tray.buttonFor(trayItem) : null
    const point = button ? button.mapToItem(null, 0, 0) : null
    push(trayItem.menu, point ? { below: true, x: point.x, width: button.width } : null)
    if (shell && shell.registerPanel) shell.registerPanel(root)
    if (shell && shell.claimPanel) shell.claimPanel(root)
    shown = true
  }

  property var pendingItem: null

  Process {
    id: focusedOutput
    command: Ui.Compositor.outputs()
    stdout: StdioCollector {
      onStreamFinished: {
        const monitor = Ui.Compositor.focusedMonitor(text)
        const trayItem = root.pendingItem
        root.pendingItem = null
        if (monitor && trayItem) root.openFor(trayItem, monitor.name)
      }
    }
  }

  function trigger(level, row, selectFirst) {
    if (!row || !row.enabled || row.isSeparator) return
    if (row.hasChildren) {
      openChild(level, row, selectFirst)
      return
    }
    row.triggered()
    close()
  }

  function openChild(level, row, selectFirst) {
    const open = stack[level + 1]
    if (open && open.source === row) return
    truncate(level + 1)
    const card = cards.itemAt(level)
    if (card) push(row, card.rowAnchor(card.current), selectFirst) // qmllint disable missing-property
  }

  function onKey(event) {
    const level = depth - 1
    const rows = rowsAt(level)
    const current = cards.itemAt(level)?.current ?? -1 // qmllint disable missing-property
    const row = current >= 0 ? rows[current] : null
    const text = event.text
    if (event.key === Qt.Key_Escape) close()
    else if (event.key === Qt.Key_Down || text === "j") select(level, TrayModel.step(rows, current, true))
    else if (event.key === Qt.Key_Up || text === "k") select(level, TrayModel.step(rows, current, false))
    else if (event.key === Qt.Key_Right || text === "l") {
      if (row && row.hasChildren && row.enabled) openChild(level, row, true)
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace || text === "h") pop()
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      if (!settling) trigger(level, row, true)
    }
    else return
    event.accepted = true
  }

  // Blocks a repeating Enter from triggering a submenu's first row.
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

  // Delays hover-opening so a diagonal move toward a submenu does not switch it.
  property var hoverTarget: null

  Timer {
    id: hoverTimer
    interval: 150
    onTriggered: {
      const target = root.hoverTarget
      if (target && target.level < root.depth && root.cursor[target.level] === target.index) {
        root.openChild(target.level, root.rowsAt(target.level)[target.index])
      }
    }
  }

  // Rows rebuilt or scrolled under a resting pointer report hover too; act on real motion only.
  property point pointer: Qt.point(-1, -1)

  function moved(point) {
    if (point.x === pointer.x && point.y === pointer.y) return false
    const first = pointer.x < 0
    pointer = point
    return !first
  }

  function hover(level, index) {
    select(level, index)
    const row = rowsAt(level)[index]
    const open = stack[level + 1]
    if (open && open.source !== row) truncate(level + 1)
    hoverTarget = row && row.hasChildren && row.enabled ? { level: level, index: index } : null
    if (hoverTarget) hoverTimer.restart()
  }

  onShownChanged: if (shown) keys.forceActiveFocus(); else reset()

  visible: shown
  anchors { top: true; bottom: true; left: true; right: true }
  // Keeps the bar's exclusive zone, so the area starts at the bar's bottom edge.
  exclusiveZone: 0
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  // Demoting an exclusive panel loses its keyboard focus on niri.
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  MouseArea {
    anchors.fill: parent
    enabled: root.shown
    onClicked: root.close()
  }

  Item {
    id: keys
    focus: true
    Keys.onPressed: function (event) { root.onKey(event) }
  }

  FontMetrics {
    id: metrics
    font.family: Ui.Fonts.mono
    font.pixelSize: 14
  }

  ListModel {
    id: levels
  }

  Repeater {
    id: cards
    model: levels

    Rectangle {
      id: card

      required property int index

      // Read once: stack changes must not rebuild this card's rows.
      property var level: null
      Component.onCompleted: level = root.stack[index]

      readonly property var rows: level ? root.rowsFor(level.opener, index) : []
      readonly property int current: root.cursor[index] === -2
        ? TrayModel.step(rows, -1, true)
        : root.cursor[index] ?? -1
      readonly property int rowsHeight: rows.reduce((sum, row) => sum + (row.isSeparator ? 9 : 28), 0)
        + Math.max(0, rows.length - 1) * list.spacing
      readonly property int labelWidth: rows.reduce((widest, row) => row.isSeparator ? widest
        : Math.max(widest, metrics.advanceWidth((row.text || "") + (row.hasChildren ? " ›" : ""))), 0)
      readonly property var position: TrayModel.place(level ? level.anchor : null,
        width, height, root.width, root.height)

      // Anchor for the submenu of row, in window coordinates.
      function rowAnchor(row) {
        const delegate = list.itemAtIndex(row)
        const y = delegate ? delegate.mapToItem(null, 0, 0).y : card.y
        return { x: card.x, width: card.width, y: y }
      }

      x: position.x
      y: position.y
      width: TrayModel.clamp(Math.ceil(labelWidth) + 54, 160, 360)
      height: Math.max(40, Math.min(rowsHeight + 12, root.height - 16))
      radius: 8
      // The root card hangs from the bar.
      topLeftRadius: index === 0 ? 0 : radius
      topRightRadius: index === 0 ? 0 : radius
      color: root.shell.palette.bg
      border.color: root.shell.palette.dim
      border.width: 1

      MouseArea {
        anchors.fill: parent
      }

      ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        spacing: 2
        model: card.rows
        currentIndex: card.current
        highlightFollowsCurrentItem: false
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Rectangle {
          id: row

          required property var modelData
          required property int index

          width: list.width
          height: modelData.isSeparator ? 9 : 28
          radius: 4
          color: "transparent"
          border.color: row.index === card.current ? root.shell.palette.fg : "transparent"
          border.width: 1
          opacity: modelData.enabled ? 1 : 0.45

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

            Text {
              width: 14
              color: root.shell.palette.fg
              font.family: Ui.Fonts.mono
              font.pixelSize: 14
              text: row.modelData.buttonType === QsMenuButtonType.CheckBox
                ? (row.modelData.checkState === Qt.Checked ? "󰄲" : "󰄱")
                : row.modelData.buttonType === QsMenuButtonType.RadioButton
                  ? (row.modelData.checkState === Qt.Checked ? "󰐾" : "󰄴")
                  : ""
            }

            Text {
              width: parent.width - 22
              color: root.shell.palette.fg
              font.family: Ui.Fonts.mono
              font.pixelSize: 14
              text: (row.modelData.text || "") + (row.modelData.hasChildren ? " ›" : "")
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !row.modelData.isSeparator
            hoverEnabled: true
            onPositionChanged: function (mouse) {
              if (root.moved(mapToItem(null, mouse.x, mouse.y))) root.hover(card.index, row.index)
            }
            onClicked: {
              root.select(card.index, row.index)
              root.trigger(card.index, row.modelData)
            }
          }
        }
      }
    }
  }
}
