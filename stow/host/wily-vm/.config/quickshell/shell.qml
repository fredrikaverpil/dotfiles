import QtQuick
import Quickshell
import Quickshell.Io

import "plugins/background" as Background
import "plugins/bar" as Bar
import "plugins/lock" as Lock
import "plugins/menu" as Menu
import "plugins/notifications" as Notifications
import "plugins/panels/audio" as Audio
import "plugins/panels/media" as Media
import "plugins/panels/monitor" as Monitor
import "plugins/panels/network" as Network
import "plugins/panels/tray" as Tray
import "plugins/polkit" as Polkit
import "plugins/services/idle" as Idle
import "plugins/services/keyboard" as Keyboard
import "plugins/services/media" as MediaService
import "plugins/services/network" as NetworkService
import "plugins/services/nightlight" as Nightlight
import "Ui" as Ui

// Wiring only: the palette, the menu's entry table, and the services and
// surfaces themselves.
ShellRoot {
  id: root

  readonly property alias menu: menu
  readonly property alias background: background
  readonly property alias notifications: notifications
  readonly property alias nightlight: nightlight
  readonly property alias idle: idle
  readonly property alias keyboard: keyboard
  readonly property alias media: media
  readonly property alias display: display
  readonly property alias network: network
  readonly property alias networkService: networkService
  readonly property alias audio: audio
  readonly property alias tray: tray

  // Overlay panels leave this strip click-through, so a click reaches the bar
  // button behind them rather than their dismissal surface.
  readonly property int barHeight: 32
  property var panels: []

  function registerPanel(panel) {
    if (panel && panels.indexOf(panel) < 0) panels = panels.concat([panel])
  }

  // Only one overlay surface at a time.
  function claimPanel(panel) {
    for (let index = 0; index < panels.length; index++) {
      const candidate = panels[index]
      if (candidate !== panel && candidate.shown) candidate.close()
    }
  }

  // The dconf key is the source of truth, not this property:
  // xdg-desktop-portal-gtk republishes it as org.freedesktop.appearance, which
  // is what flips Ghostty live, and Neovim follows the terminal over OSC 11.
  property bool dark: true
  // GTK reads this dconf key itself; the bar reads the same value so its text
  // scales with the rest of the desktop.
  property real textScale: 1
  // `dim` is chrome (borders, placeholder text) and sits close to the
  // background — around 1.5:1 on `bg` in dark mode, so it is unreadable as
  // text. `off` is for text that must stay legible while reading as inactive.
  readonly property var darkPalette: ({ bg: "#1C1917", fg: "#B4BDC3", sel: "#3D4042", dim: "#403833", off: "#6E6864" })
  readonly property var lightPalette: ({ bg: "#F0EDEC", fg: "#2C363C", sel: "#CBD9E3", dim: "#CFC1BA", off: "#8F857D" })
  readonly property var palette: dark ? darkPalette : lightPalette

  // A KDE app repaints its view area from kdeglobals' [Colors:View], not from
  // the palette the rest of its window follows; with no kdeglobals it falls
  // back to Breeze light (Dolphin's file area stays white in dark mode).
  // kwriteconfig6, not a plain write: KConfig caches the file per process and
  // only its --notify D-Bus signal drops that cache. The notify does not
  // repaint by itself, so this must run before the dconf keys move.
  function kdeglobalsWrite(on) {
    const p = on ? darkPalette : lightPalette
    const rgb = hex => {
      const c = Qt.color(hex)
      return [Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255)].join(",")
    }
    const set = (key, hex) =>
      "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key " +
      key + " '" + rgb(hex) + "'; "
    return set("BackgroundNormal", p.bg) + set("ForegroundNormal", p.fg)
  }

  function writeKdeglobals() {
    kdeglobals.command = ["sh", "-c", kdeglobalsWrite(root.dark)]
    kdeglobals.running = true
  }

  function setDark(on) {
    const scheme = on ? "prefer-dark" : "prefer-light"
    const gtk = on ? "Adwaita-dark" : "Adwaita"
    write.command = ["sh", "-c",
      kdeglobalsWrite(on) +
      "dconf write /org/gnome/desktop/interface/color-scheme \"'" + scheme + "'\"; " +
      "dconf write /org/gnome/desktop/interface/gtk-theme \"'" + gtk + "'\""]
    write.running = true
  }

  // A dconf write from a shell bypasses setDark. That write can land after the
  // app has repainted; the next toggle corrects it.
  onDarkChanged: writeKdeglobals()

  Process { id: write }
  Process { id: kdeglobals }

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

  // Watched as well as written, so a `dconf write` from a shell moves the bar.
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
      onStreamFinished: {
        root.dark = text.indexOf("prefer-light") < 0
        // Unconditional: onDarkChanged stays silent when dconf agrees with the
        // default, and an app started before the file exists caches the white.
        root.writeKdeglobals()
      }
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

  // Dotted ids imply the hierarchy: "style.theme.dark" is a child of
  // "style.theme". Kind is inferred -- an entry with an action fires, one with
  // children descends, one with a provider fills its level from elsewhere.
  // Lives here rather than in Menu.qml because the actions reach every service.
  //
  // `enabled: false` is a row with nothing behind it yet: dim and inert rather
  // than absent, so what is still missing stays visible.
  readonly property var menuItems: ({
    "apps": { icon: "󰀻", label: "Apps", provider: "apps" },
    "learn": { icon: "󰧑", label: "Learn" },
    "learn.keybindings": { icon: "", label: "Keybindings", provider: "binds" },
    "learn.compositor": { icon: "", label: Ui.Compositor.niri ? "niri" : "Hyprland", enabled: false },
    "learn.nixos": { icon: "", label: "NixOS", enabled: false },
    "style": { icon: "", label: "Style" },
    "style.wallpaper": { icon: "", label: "Wallpaper", action: () => background.open() },
    "style.theme": { icon: "", label: "Theme" },
    "style.theme.dark": { icon: "", label: "Dark", action: () => root.setDark(true) },
    "style.theme.light": { icon: "", label: "Light", action: () => root.setDark(false) },
    "trigger": { icon: "󱓞", label: "Trigger" },
    // wl-copy needs an explicit --type; it does not sniff the PNG.
    "trigger.screenshot": { icon: "", label: "Screenshot", action: () => root.run(
      "mkdir -p $HOME/Pictures/screenshots && " +
      "f=$HOME/Pictures/screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png && " +
      "grim \"$f\" && wl-copy --type image/png < \"$f\"") },
    "trigger.emoji": { icon: "", label: "Emoji", enabled: false },
    "trigger.color": { icon: "󰃉", label: "Color picker", enabled: false },
    "trigger.share": { icon: "", label: "Share", enabled: false },
    "media": { icon: media.icon, label: "Media", action: () => media.open() },
    // The bar's tray icons are mouse-only, so Enter here raises the app; its
    // own menu stays on the bar icon's right click.
    "tray": { icon: "󰘔", label: "Tray", provider: "tray" },
    "setup": { icon: "", label: "Setup" },
    "setup.display": { icon: "󰍹", label: "Display", action: () => display.open() },
    "setup.network": { icon: "󰈀", label: "Network", action: () => network.open() },
    "setup.audio": { icon: "󰕾", label: "Audio", action: () => audio.open() },
    "setup.nightlight": { icon: "󰆔", label: "Nightlight", action: () => nightlight.toggle() },
    // Order must match `kb_layout` / `layout` in the compositor configs, and
    // the `codes` in the keyboard service.
    "setup.keyboard": { icon: "󰌌", label: "Keyboard layout" },
    "setup.keyboard.us": {
      icon: keyboard.index === 0 ? "󰄬" : "󰌌",
      label: "English (US)",
      action: () => keyboard.set(0)
    },
    "setup.keyboard.se": {
      icon: keyboard.index === 1 ? "󰄬" : "󰌌",
      label: "Swedish",
      action: () => keyboard.set(1)
    },
    "system": { icon: "", label: "System" },
    "system.close": { icon: "󰅖", label: "Close window", action: () => Quickshell.execDetached(
      Ui.Compositor.closeWindow())
    },
    "system.notifications": { icon: "󰂚", label: "Notifications" },
    "system.notifications.history": { icon: "󰎟", label: "History", action: () => notifications.showHistory() },
    "system.notifications.dnd": { icon: "󰂛", label: "Toggle Do Not Disturb", action: () => notifications.setDoNotDisturb(!notifications.doNotDisturb) },
    "system.lock": { icon: "", label: "Lock", action: () => lock.beginLock() },
    "system.idle": {
      icon: idle.enabled ? "󰾪" : "󰅶",
      label: idle.enabled ? "Disable idle locking" : "Enable idle locking",
      action: () => idle.setEnabled(!idle.enabled)
    },
    "system.suspend": { icon: "󰒲", label: "Suspend", action: () => root.run("systemctl suspend") },
    "system.logout": { icon: "󰍃", label: "Logout", action: () => root.run("uwsm stop") },
    "system.reboot": { icon: "󰜉", label: "Reboot", action: () => root.run("systemctl reboot") },
    "system.shutdown": { icon: "󰐥", label: "Shutdown", action: () => root.run("systemctl poweroff") },
  })

  function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

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

  Keyboard.Service {
    id: keyboard
  }

  Nightlight.Service {
    id: nightlight
    shell: root
  }

  MediaService.Service {
    id: mediaService
  }

  Polkit.PolkitAgent {
    id: polkit
    shell: root
  }

  Background.Background {
    id: background
    shell: root
  }

  Media.Panel {
    id: media
    shell: root
    service: mediaService
  }

  Monitor.Panel {
    id: display
    shell: root
  }

  NetworkService.Service {
    id: networkService
  }

  Network.Panel {
    id: network
    shell: root
    service: networkService
  }

  Audio.Panel {
    id: audio
    shell: root
  }

  Tray.Panel {
    id: tray
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
