import QtQuick
import Quickshell
import Quickshell.Io

import "../../Ui" as Ui

// The launcher. `items` is the entry table, injected by shell.qml so this file
// stays the mechanism and that one stays the wiring.
Ui.Panel {
  id: menu

  required property var items

  property string level: "root"

  cardWidth: wide ? 900 : 600
  cardHeight: wide ? 640 : 420

  // Keybindings. hyprland.lua writes this as it registers each bind, because
  // `hyprctl binds` cannot name a code: chord -- see that file. Watched, so a
  // config reload refreshes the sheet without restarting the shell.
  property var binds: []

  FileView {
    id: bindsFile
    path: Quickshell.env("HOME") + "/.local/state/hypr-binds.tsv"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: menu.binds = text().trim().split("\n")
      .filter(line => line.length > 0)
      .map(line => {
        const columns = line.split("\t")
        return { chord: columns[0], label: columns[1] || "", enabled: true }
      })
  }

  // Children are the ids one dot deeper than their parent; "root" is the ids
  // with no dot at all.
  function childrenOf(parent) {
    const prefix = parent === "root" ? "" : parent + "."
    const depth = parent === "root" ? 1 : parent.split(".").length + 1
    return Object.keys(menuItems).filter(id =>
      id.startsWith(prefix) && id.split(".").length === depth)
  }

  // Every id below `parent` at any depth, which is what a search covers.
  function descendantsOf(parent) {
    const prefix = parent === "root" ? "" : parent + "."
    return Object.keys(menuItems).filter(id => id !== parent && id.startsWith(prefix))
  }

  // "Style › Theme" for a hit further down; empty for a direct child of the
  // level being searched, which needs no breadcrumb.
  function pathFrom(id, level) {
    const parts = id.split(".").slice(0, -1)
    const skip = level === "root" ? 0 : level.split(".").length
    return parts.slice(skip).map((part, i) =>
      menuItems[parts.slice(0, skip + i + 1).join(".")].label).join(" › ")
  }

  function rowFor(id, level) {
    const child = menuItems[id]
    return {
      id: id,
      label: child.label,
      icon: child.icon,
      detail: pathFrom(id, level),
      enabled: child.enabled !== false,
      entry: null,
      action: child.action || null,
      submenu: child.provider !== undefined || childrenOf(id).length > 0,
    }
  }

  function appRows(detail) {
    return DesktopEntries.applications.values
      .filter(entry => !entry.noDisplay)
      .sort((a, b) => a.name.localeCompare(b.name))
      .map(entry => ({ label: entry.name, icon: "", detail: detail || "", enabled: true, entry: entry }))
  }

  // Reached from Hyprland with `qs ipc call menu toggle`. The bar button calls
  // menu.toggle() directly -- same process, no subprocess needed.
  IpcHandler {
    target: "menu"

    function toggle(): void { menu.toggle() }
    function open(): void { menu.open("root") }
    function close(): void { menu.close() }
    // Not `show`: `qs ipc show` is a CLI subcommand, so the argument parser
    // eats the name before the call ever reaches this handler.
    function level(id: string): void { menu.open(id) }
  }

  // A binding, not a one-shot: the desktop-entry scan finishes a few seconds
  // after startup, so an app list built once at open() comes up empty.
  readonly property var rows: {
    const item = menu.items[level]
    const query = input.text.toLowerCase()

    // Chord as well as label, so "super" and "workspace" both narrow the
    // keybinding sheet.
    const matches = row => row.label.toLowerCase().indexOf(query) >= 0
      || (row.chord !== undefined && row.chord.toLowerCase().indexOf(query) >= 0)

    if (item && item.provider === "binds")
      return query.length === 0 ? menu.binds : menu.binds.filter(matches)
    if (item && item.provider === "apps")
      return query.length === 0 ? menu.appRows() : menu.appRows().filter(matches)
    if (query.length === 0)
      return menu.childrenOf(level).map(id => menu.rowFor(id, level))

    // A search covers the whole subtree below the current level, the way
    // Omarchy's rebuildDisplay does, so "ghostty" or "lock" reaches an
    // action from the root without walking down to it. Deeper hits carry
    // their path and sort after the direct children -- their divider and
    // score tiers are not ported. Apps are in the tree upstream; here they
    // are the one provider joined in, since the ~100 keybinding rows would
    // swamp any root search. Dim rows drop out, as they do upstream: there
    // is nothing behind them to reach.
    const found = menu.descendantsOf(level).map(id => menu.rowFor(id, level))
    return (level === "root" ? found.concat(menu.appRows("Apps")) : found)
      .filter(row => row.enabled && matches(row))
      .sort((a, b) => (a.detail ? 1 : 0) - (b.detail ? 1 : 0))
  }

  // Deferred: ListView resets currentIndex itself when the model changes,
  // and does it after this handler runs.
  onRowsChanged: Qt.callLater(selectFirstEnabled)

  function selectFirstEnabled() {
    const first = rows.findIndex(row => row.enabled)
    list.currentIndex = first < 0 ? 0 : first
  }

  // A dim row is skipped rather than merely inert, so holding Down never
  // parks the highlight on something Enter will ignore. Wraps, so the last
  // row leads back to the first.
  function move(steps) {
    const count = rows.length
    if (count === 0) return
    const delta = steps > 0 ? 1 : -1
    let index = list.currentIndex

    for (let moved = 0; moved < Math.abs(steps); moved++) {
      let candidate = index
      for (let tried = 0; tried < count; tried++) {
        candidate = (candidate + delta + count) % count
        if (rows[candidate].enabled) break
      }
      index = candidate
    }

    list.currentIndex = index
  }

  readonly property string title: level === "root" ? "Go" : menu.items[level].label

  // The keybinding sheet needs a bigger window: its longest chord is 28
  // characters before the description even starts, and it is ~100 rows.
  readonly property bool wide: level !== "root" && menu.items[level].provider === "binds"

  function open(target) {
    if (shell && shell.registerPanel) shell.registerPanel(menu)
    if (shell && shell.claimPanel) shell.claimPanel(menu)
    level = target
    input.text = ""
    shown = true
    input.forceActiveFocus()
    Qt.callLater(selectFirstEnabled)
  }

  function toggle() { shown ? close() : open("root") }

  // Escape and Left back out one level and only close at the root, so a
  // wrong turn costs one key rather than reopening the menu.
  function back() {
    if (level === "root") close()
    else open(level.indexOf(".") >= 0 ? level.split(".").slice(0, -1).join(".") : "root")
  }

  function activate() {
    const row = rows[list.currentIndex]
    if (!row || !row.enabled) return

    if (row.entry) {
      close()
      // uwsm-app puts the app in its own scope under app-graphical.slice, so
      // it survives `systemctl --user restart quickshell` while iterating.
      Quickshell.execDetached(["uwsm-app", "--", row.entry.id + ".desktop"])
    } else if (row.action) {
      close()
      row.action()
    } else if (row.id) {
      open(row.id)
    }
  }


  Text {
    color: menu.shell.palette.dim
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    text: menu.title
  }

  TextInput {
    id: input
    width: parent.width
    clip: true
    color: menu.shell.palette.fg
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 18
    focus: true

    Text {
      anchors.fill: parent
      visible: input.text.length === 0
      color: menu.shell.palette.dim
      font: input.font
      text: "Search…"
    }

    Keys.onPressed: function (event) {
      if (event.key === Qt.Key_Escape) menu.back()
      else if (event.key === Qt.Key_Left && input.text.length === 0) menu.back()
      else if (event.key === Qt.Key_Down) menu.move(1)
      else if (event.key === Qt.Key_Up) menu.move(-1)
      else if (event.key === Qt.Key_PageDown) menu.move(10)
      else if (event.key === Qt.Key_PageUp) menu.move(-10)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) menu.activate()
      else if (event.key === Qt.Key_Right && input.text.length === 0) menu.activate()
      else return
      event.accepted = true
    }
  }

  Rectangle {
    width: parent.width
    height: 1
    color: menu.shell.palette.dim
  }

  ListView {
    id: list
    width: parent.width
    height: parent.height - y
    clip: true
    model: menu.rows

    delegate: Rectangle {
      required property var modelData
      required property int index

      width: list.width
      height: 36
      color: index === list.currentIndex ? menu.shell.palette.sel : "transparent"
      radius: 4

      Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8
        spacing: 10

        Text {
          width: 20
          visible: modelData.chord === undefined
          color: modelData.enabled ? menu.shell.palette.fg : menu.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          text: modelData.icon || ""
        }

        // Monospace, so a fixed width lines every chord up in a column
        // the eye can read straight down.
        Text {
          width: 290
          visible: modelData.chord !== undefined
          color: menu.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          text: modelData.chord || ""
        }

        Text {
          color: modelData.enabled ? menu.shell.palette.fg : menu.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          // Capped only where a breadcrumb follows, so a long label
          // elides instead of pushing it off the panel. Uncapped
          // otherwise -- the keybinding sheet has 36-character labels.
          width: modelData.detail ? Math.min(implicitWidth, 300) : implicitWidth
          text: modelData.label + (modelData.submenu ? " ›" : "")
          elide: Text.ElideRight
        }

        // Where a search hit below the current level lives.
        Text {
          visible: (modelData.detail || "") !== ""
          color: menu.shell.palette.off
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          text: modelData.detail || ""
          elide: Text.ElideRight
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (!modelData.enabled) return
          list.currentIndex = index
          menu.activate()
        }
      }
    }
  }
}
