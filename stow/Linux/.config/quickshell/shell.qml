import QtQuick
import Quickshell
import Quickshell.Io

import "plugins/background" as Background
import "plugins/bar" as Bar
import "plugins/lock" as Lock
import "plugins/menu" as Menu
import "plugins/notifications" as Notifications
import "plugins/panels/monitor" as Monitor
import "plugins/panels/network" as Network
import "plugins/polkit" as Polkit
import "plugins/services/idle" as Idle
import "plugins/services/nightlight" as Nightlight

// Wiring only: the palette every surface reads, the menu's entry table, and
// the services and surfaces themselves. Each of those lives in its own file
// under plugins/, on the paths Omarchy uses, so upstream stays diffable.
ShellRoot {
  id: root

  readonly property alias menu: menu
  readonly property alias background: background
  readonly property alias notifications: notifications
  readonly property alias nightlight: nightlight
  readonly property alias display: display
  readonly property alias network: network

  // All overlay panels leave this strip click-through so a second click
  // reaches its bar button rather than their full-screen dismissal surface.
  readonly property int barHeight: 32
  property var panels: []

  function registerPanel(panel) {
    if (panel && panels.indexOf(panel) < 0) panels = panels.concat([panel])
  }

  // Opening a panel closes any other. Only one overlay surface at a time.
  function claimPanel(panel) {
    for (let index = 0; index < panels.length; index++) {
      const candidate = panels[index]
      if (candidate !== panel && candidate.shown) candidate.close()
    }
  }

  // Light/dark. The dconf key is the source of truth, not a property of ours:
  // xdg-desktop-portal-gtk republishes it as org.freedesktop.appearance, which
  // is what flips Ghostty's theme live, and Neovim follows the terminal over
  // OSC 11. gtk-theme comes along so GTK apps switch too.
  property bool dark: true
  // GTK reads this dconf key itself; the bar reads the same value so its text
  // changes size with the rest of the desktop rather than remaining fixed.
  property real textScale: 1
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

  function setTextScale(value) {
    const scale = Number(value)
    if (!isFinite(scale) || scale < 0.8 || scale > 1.5) return
    textScale = scale
    textScaleWrite.command = [
      "dconf",
      "write",
      "/org/gnome/desktop/interface/text-scaling-factor",
      String(scale),
    ]
    textScaleWrite.running = true
  }

  function updateTextScale(value) {
    const scale = parseFloat(String(value))
    if (isFinite(scale) && scale > 0) textScale = scale
  }

  Process { id: textScaleWrite }

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

  Process {
    running: true
    command: ["dconf", "watch", "/org/gnome/desktop/interface/text-scaling-factor"]
    stdout: SplitParser {
      onRead: line => root.updateTextScale(line)
    }
  }

  Process {
    running: true
    command: ["dconf", "read", "/org/gnome/desktop/interface/text-scaling-factor"]
    stdout: StdioCollector {
      onStreamFinished: root.updateTextScale(text)
    }
  }

  // The menu's entries, in Omarchy's omarchy-menu.jsonc shape minus its
  // machinery: dotted ids imply the hierarchy, so "style.theme.dark" is a
  // child of "style.theme" and no nesting syntax is needed. Kind is inferred -- an entry with an action
  // fires, one with children descends, one with a provider fills its level
  // from somewhere else. Their Menu.qml and MenuModel.js are ~2000 lines of
  // jsonc parsing, plugin manifests and provider indirection; this is ~25
  // entries and does not need any of it. The table sits here rather than in
  // Menu.qml because its actions reach every other service.
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
    "style.background": { icon: "", label: "Background", action: () => background.open() },
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
    "setup.display": { icon: "󰍹", label: "Display", action: () => display.open() },
    "setup.network": { icon: "󰈀", label: "Network", action: () => network.open() },
    "setup.nightlight": { icon: "󰆔", label: "Nightlight", action: () => nightlight.toggle() },
    "system": { icon: "", label: "System" },
    "system.close": { icon: "󰅖", label: "Close window", action: () => Quickshell.execDetached(
      ["hyprctl", "dispatch", "hl.dsp.window.close()"])
    },
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

  Nightlight.Service {
    id: nightlight
    shell: root
  }

  Polkit.PolkitAgent {
    id: polkit
    shell: root
  }

  Background.Background {
    id: background
    shell: root
  }

  Monitor.Panel {
    id: display
    shell: root
  }

  Network.Panel {
    id: network
    shell: root
  }

  Menu.Menu {
    id: menu
    shell: root
    items: root.menuItems
  }

  Bar.Bar {
    shell: root
  }
}
