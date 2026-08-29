import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "plugins/lock" as Lock
import "plugins/notifications" as Notifications
import "plugins/polkit" as Polkit
import "plugins/services/idle" as Idle

ShellRoot {
  id: root

  // Wallpaper. Images live in ~/Pictures/wallpapers — outside this repo, so
  // nothing binary gets committed — and the pick is per mode, persisted as a
  // path in ~/.local/state/wallpaper-{dark,light}. The gradient below shows
  // through until a mode has been given a picture.
  readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
  property list<string> wallpapers: []
  property string darkPick: ""
  property string lightPick: ""
  readonly property string wallpaper: dark ? darkPick : lightPick

  function setWallpaper(path) {
    if (dark) {
      darkPick = path
      darkState.setText(path + "\n")
    } else {
      lightPick = path
      lightState.setText(path + "\n")
    }
  }

  Process {
    id: scan
    running: true
    command: ["find", root.wallpaperDir, "-type", "f",
              "-iregex", ".*\\.\\(png\\|jpg\\|jpeg\\|webp\\)"]
    stdout: StdioCollector {
      onStreamFinished: root.wallpapers = text.trim().split("\n").filter(l => l.length > 0).sort()
    }
  }

  FileView {
    id: darkState
    path: Quickshell.env("HOME") + "/.local/state/wallpaper-dark"
    atomicWrites: true
    printErrors: false
    onLoaded: root.darkPick = text().trim()
  }

  FileView {
    id: lightState
    path: Quickshell.env("HOME") + "/.local/state/wallpaper-light"
    atomicWrites: true
    printErrors: false
    onLoaded: root.lightPick = text().trim()
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void { picker.toggle() }
    function open(): void { picker.open() }
    function close(): void { picker.close() }
    function rescan(): void { scan.running = true }
    function set(path: string): void { root.setWallpaper(path) }
  }

  // Light/dark. The dconf key is the source of truth, not a property of ours:
  // xdg-desktop-portal-gtk republishes it as org.freedesktop.appearance, which
  // is what flips Ghostty's theme live, and Neovim follows the terminal over
  // OSC 11. gtk-theme comes along so GTK apps switch too.
  property bool dark: true
  // `dim` is chrome — borders, placeholder text — and is deliberately close to
  // the background. `off` is for text that must stay readable while reading as
  // inactive, so it sits between the two; `dim` on `bg` is around 1.5:1 in
  // dark mode, which is invisible rather than subdued.
  readonly property var palette: dark
    ? ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })
    : ({ bg: "#F0EDEC", fg: "#2C363C", sel: "#CBD9E3", dim: "#CFC1BA", off: "#8F857D" })

  function setDark(on) {
    const scheme = on ? "prefer-dark" : "prefer-light"
    const gtk = on ? "Adwaita-dark" : "Adwaita"
    write.command = ["sh", "-c",
      "dconf write /org/gnome/desktop/interface/color-scheme \"'" + scheme + "'\"; " +
      "dconf write /org/gnome/desktop/interface/gtk-theme \"'" + gtk + "'\""]
    write.running = true
  }

  Process { id: write }

  IpcHandler {
    target: "theme"

    function toggle(): void { root.setDark(!root.dark) }
    function dark(): void { root.setDark(true) }
    function light(): void { root.setDark(false) }
  }

  // Watched, not just written, so a `dconf write` from a shell moves the bar
  // too. dconf watch prints the key on one line and the value on the next.
  Process {
    running: true
    command: ["dconf", "watch", "/org/gnome/desktop/interface/"]
    stdout: SplitParser {
      onRead: line => {
        if (line.indexOf("prefer-dark") >= 0) root.dark = true
        else if (line.indexOf("prefer-light") >= 0) root.dark = false
      }
    }
  }

  Process {
    running: true
    command: ["dconf", "read", "/org/gnome/desktop/interface/color-scheme"]
    stdout: StdioCollector {
      onStreamFinished: root.dark = text.indexOf("prefer-light") < 0
    }
  }

  // These use Omarchy-compatible plugin paths while remaining independent of
  // its plugin loader and shared QML framework. Keeping the paths aligned
  // makes it practical to compare later fixes and features upstream.
  Notifications.Service {
    id: notifications
    shell: root
  }

  Lock.Service {
    id: lock
    shell: root
  }

  Idle.Service {
    id: idle
    lockService: lock
  }

  Polkit.PolkitAgent {
    id: polkit
    shell: root
  }

  // Bar chrome, so every button hovers and reads the same.
  component BarButton: Rectangle {
    id: btn

    property alias label: btnLabel.text
    signal activated

    implicitWidth: btnLabel.implicitWidth + 16
    width: implicitWidth
    height: 24
    radius: 4
    color: btnMouse.containsMouse ? root.palette.sel : "transparent"

    Text {
      id: btnLabel
      anchors.centerIn: parent
      color: root.palette.fg
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 14
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: btn.activated()
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  // Menu. Omarchy's omarchy-menu.jsonc shape, minus its machinery: dotted ids
  // imply the hierarchy, so "style.theme.dark" is a child of "style.theme" and
  // no nesting syntax is needed. Kind is inferred -- an entry with an action
  // fires, one with children descends, one with a provider fills its level
  // from somewhere else. Their Menu.qml and MenuModel.js are ~2000 lines of
  // jsonc parsing, plugin manifests and provider indirection; this is ~25
  // entries and does not need any of it.
  //
  // `enabled: false` lists a row that has nothing behind it yet: dim and
  // inert, rather than absent, so the shape of what is still missing stays
  // visible. Those rows are the ones to edit when the feature lands.
  readonly property var menuItems: ({
    "apps": { icon: "󰀻", label: "Apps", provider: "apps" },
    "learn": { icon: "󰧑", label: "Learn" },
    "learn.keybindings": { icon: "", label: "Keybindings", provider: "binds" },
    "learn.hyprland": { icon: "", label: "Hyprland", enabled: false },
    "learn.nixos": { icon: "", label: "NixOS", enabled: false },
    "style": { icon: "", label: "Style" },
    "style.background": { icon: "", label: "Background", action: () => picker.open() },
    "style.theme": { icon: "", label: "Theme" },
    "style.theme.dark": { icon: "", label: "Dark", action: () => root.setDark(true) },
    "style.theme.light": { icon: "", label: "Light", action: () => root.setDark(false) },
    "trigger": { icon: "󱓞", label: "Trigger" },
    "trigger.screenshot": { icon: "", label: "Screenshot", action: () => root.run(
      "mkdir -p ~/Pictures/screenshots && " +
      "grim ~/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png") },
    "trigger.emoji": { icon: "", label: "Emoji", enabled: false },
    "trigger.color": { icon: "󰃉", label: "Color picker", enabled: false },
    "trigger.share": { icon: "", label: "Share", enabled: false },
    "setup": { icon: "", label: "Setup" },
    "setup.display": { icon: "󰍹", label: "Display", enabled: false },
    "setup.nightlight": { icon: "󰆔", label: "Nightlight", enabled: false },
    "system": { icon: "", label: "System" },
    "system.notifications": { icon: "󰂚", label: "Notifications" },
    "system.notifications.history": { icon: "󰎟", label: "History", action: () => notifications.showHistory() },
    "system.notifications.dnd": { icon: "󰂛", label: "Toggle Do Not Disturb", action: () => notifications.setDoNotDisturb(!notifications.doNotDisturb) },
    "system.lock": { icon: "", label: "Lock", action: () => lock.beginLock() },
    "system.idle": { icon: "󰅶", label: "Toggle idle locking", action: () => idle.setEnabled(!idle.enabled) },
    "system.suspend": { icon: "󰒲", label: "Suspend", action: () => root.run("systemctl suspend") },
    "system.logout": { icon: "󰍃", label: "Logout", action: () => root.run("uwsm stop") },
    "system.reboot": { icon: "󰜉", label: "Reboot", action: () => root.run("systemctl reboot") },
    "system.shutdown": { icon: "󰐥", label: "Shutdown", action: () => root.run("systemctl poweroff") },
  })

  function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

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
    onLoaded: root.binds = text().trim().split("\n")
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

  PanelWindow {
    id: menu

    property bool shown: false
    property string level: "root"

    // A binding, not a one-shot: the desktop-entry scan finishes a few seconds
    // after startup, so an app list built once at open() comes up empty.
    readonly property var rows: {
      const item = root.menuItems[level]
      const query = input.text.toLowerCase()
      let out

      if (item && item.provider === "binds") {
        out = root.binds
      } else if (item && item.provider === "apps") {
        out = DesktopEntries.applications.values
          .filter(entry => !entry.noDisplay)
          .sort((a, b) => a.name.localeCompare(b.name))
          .map(entry => ({ label: entry.name, icon: "", enabled: true, entry: entry }))
      } else {
        out = root.childrenOf(level).map(id => {
          const child = root.menuItems[id]
          return {
            id: id,
            label: child.label,
            icon: child.icon,
            enabled: child.enabled !== false,
            entry: null,
            action: child.action || null,
            submenu: child.provider !== undefined || root.childrenOf(id).length > 0,
          }
        })
      }

      if (query.length === 0) return out

      // Chord as well as label, so "super" and "workspace" both narrow the
      // keybinding sheet.
      return out.filter(row =>
        row.label.toLowerCase().indexOf(query) >= 0
        || (row.chord !== undefined && row.chord.toLowerCase().indexOf(query) >= 0))
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

    readonly property string title: level === "root" ? "Go" : root.menuItems[level].label

    // The keybinding sheet needs a bigger window: its longest chord is 28
    // characters before the description even starts, and it is ~100 rows.
    readonly property bool wide: level !== "root" && root.menuItems[level].provider === "binds"

    function open(target) {
      level = target
      input.text = ""
      shown = true
      input.forceActiveFocus()
      Qt.callLater(selectFirstEnabled)
    }

    function close() { shown = false }
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

    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: menu.close()
    }

    Rectangle {
      anchors.centerIn: parent
      width: menu.wide ? 900 : 600
      height: menu.wide ? 640 : 420
      radius: 8
      color: root.palette.bg
      border.color: root.palette.dim
      border.width: 1

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
          color: root.palette.dim
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          text: menu.title
        }

        TextInput {
          id: input
          width: parent.width
          clip: true
          color: root.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
          focus: true

          Text {
            anchors.fill: parent
            visible: input.text.length === 0
            color: root.palette.dim
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
          color: root.palette.dim
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
            color: index === list.currentIndex ? root.palette.sel : "transparent"
            radius: 4

            Row {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 10

              Text {
                width: 20
                visible: modelData.chord === undefined
                color: modelData.enabled ? root.palette.fg : root.palette.off
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                text: modelData.icon || ""
              }

              // Monospace, so a fixed width lines every chord up in a column
              // the eye can read straight down.
              Text {
                width: 290
                visible: modelData.chord !== undefined
                color: root.palette.off
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                text: modelData.chord || ""
              }

              Text {
                color: modelData.enabled ? root.palette.fg : root.palette.off
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                text: modelData.label + (modelData.submenu ? " ›" : "")
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
    }
  }

  PanelWindow {
    id: picker

    property bool shown: false

    function open() {
      shown = true
      grid.currentIndex = Math.max(0, root.wallpapers.indexOf(root.wallpaper))
      grid.forceActiveFocus()
    }

    function close() { shown = false }
    function toggle() { shown ? close() : open() }

    function choose() {
      const path = root.wallpapers[grid.currentIndex]
      close()
      if (path) root.setWallpaper(path)
    }

    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: picker.close()
    }

    Rectangle {
      anchors.centerIn: parent
      width: 840
      height: 540
      radius: 8
      color: root.palette.bg
      border.color: root.palette.dim
      border.width: 1

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Text {
          color: root.palette.fg
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
          // The pick applies to the mode that is on now, so name it.
          text: "Wallpaper · " + (root.dark ? "dark" : "light")
        }

        GridView {
          id: grid
          width: parent.width
          height: parent.height - y
          clip: true
          focus: true
          cellWidth: width / 4
          cellHeight: cellWidth * 9 / 16
          model: root.wallpapers

          delegate: Item {
            required property var modelData
            required property int index

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
              anchors.fill: parent
              anchors.margins: 4
              radius: 4
              clip: true
              color: root.palette.dim
              border.color: index === grid.currentIndex ? root.palette.fg : "transparent"
              border.width: 2

              Image {
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Thumbnails, not full decodes: the source images run to megabytes.
                sourceSize.width: 480
                source: "file://" + modelData
              }

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  grid.currentIndex = index
                  picker.choose()
                }
              }
            }
          }

          Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) picker.close()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) picker.choose()
            else return
            event.accepted = true
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      WlrLayershell.layer: WlrLayer.Background
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop { position: 0.0; color: root.palette.dim }
          GradientStop { position: 1.0; color: root.palette.bg }
        }
      }

      Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        source: root.wallpaper ? "file://" + root.wallpaper : ""
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 32
      color: root.palette.bg

      BarButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 4
        label: "󰣇"
        onActivated: menu.toggle()
      }

      Text {
        anchors.centerIn: parent
        color: root.palette.fg
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
      }

      BarButton {
        id: themeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: root.dark ? "\uf186" : "\uf522"
        onActivated: root.setDark(!root.dark)
      }

      BarButton {
        anchors.right: themeButton.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        label: notifications.doNotDisturb ? "󰂛" : "󰂚"
        onActivated: notifications.showHistory()
      }
    }
  }
}
