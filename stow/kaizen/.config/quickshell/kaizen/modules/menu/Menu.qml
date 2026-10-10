import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

import "../bar/widgets/TrayModel.js" as TrayModel
import "../services/bluetooth/BluetoothModel.js" as BluetoothModel
import "../services/firmware/FirmwareModel.js" as FirmwareModel
import "../services/media/MediaModel.js" as MediaModel
import "../services/timezone/ZonesModel.js" as ZonesModel
import "../services/weather/PlacesModel.js" as PlacesModel
import "MenuModel.js" as Model

import "../../Ui" as Ui

Ui.Panel {
    id: menu

    required property var contextMenu

    // An item's ipc ("<target> <fn>") or compositor action names the bind that
    // runs exactly its action; its row shows that bind's keys.
    readonly property var items: Object.assign({
        "apps": {
            icon: "󰀻",
            label: "Apps",
            provider: "apps"
        },
        "keybindings": {
            icon: "\u{F11C}",
            label: "Keybindings",
            provider: "binds"
        },
        "tray": {
            icon: "󰘔",
            label: "Tray",
            provider: "tray"
        },
        // One node per plugin, plugins.<name>.
        "plugins": {
            icon: "\u{F0431}",
            label: "Plugins"
        },
        "trigger": {
            icon: "󱓞",
            label: "Trigger"
        },
        "trigger.screenshot": {
            icon: "",
            label: "Screenshot (desktop)",
            ipc: "recording shoot screen",
            action: () => menu.shell.recordingService.shoot("screen")
        },
        "trigger.screenshotWindow": {
            icon: "",
            label: "Screenshot (window)",
            action: () => menu.shell.recordingService.shoot("window")
        },
        "trigger.screenshotRegion": {
            icon: "",
            label: "Screenshot (region)",
            ipc: "recording screenshot",
            action: () => menu.shell.recordingService.screenshot()
        },
        "trigger.record": {
            icon: "󰑊",
            label: "Record screen",
            ipc: "recording toggle",
            action: () => menu.shell.recording.open()
        },
        "trigger.pause": {
            icon: menu.shell.recordingService.paused ? "󰐊" : "󰏤",
            label: menu.shell.recordingService.paused ? "Resume recording" : "Pause recording",
            ipc: "recording pause",
            enabled: menu.shell.recordingService.recording,
            action: () => menu.shell.recordingService.togglePause()
        },
        "trigger.stop": {
            icon: "󰓛",
            label: "Stop recording",
            enabled: menu.shell.recordingService.busy,
            action: () => menu.shell.recordingService.stop()
        },
        "trigger.emoji": {
            icon: "",
            label: "Emoji",
            provider: "emoji"
        },
        "trigger.clipboard": {
            icon: "\u{F014C}",
            label: "Clipboard"
        },
        "trigger.clipboard.panel": {
            icon: "󰕮",
            label: "Clipboard panel",
            action: () => menu.shell.clipboard.open()
        },
        "trigger.clipboard.clear": {
            icon: "󰃢",
            label: "Clear history",
            action: () => menu.shell.clipboard.service.clear()
        },
        "trigger.color": {
            icon: "󰃉",
            label: "Color picker",
            action: () => menu.shell.systemService.pickColor()
        },
        "trigger.close": {
            icon: "󰅖",
            label: "Close window",
            compositor: "close-window",
            action: () => Quickshell.execDetached(Ui.Compositor.closeWindow())
        },
        // One node per panel button, in bar order, each opening its panel first.
        "settings": {
            icon: "",
            label: "Settings"
        },
        "settings.weather": {
            icon: menu.shell.weatherService.icon,
            label: "Weather"
        },
        "settings.weather.panel": {
            icon: "󰕮",
            label: "Weather panel",
            action: () => menu.shell.weather.open()
        },
        "settings.weather.refresh": {
            icon: "󰑐",
            label: "Refresh",
            action: () => menu.shell.weatherService.refresh()
        },
        "settings.weather.forecast": {
            icon: "󰖐",
            label: "Today on yr.no",
            action: () => menu.shell.weather.openForecast()
        },
        "settings.weather.location": {
            icon: "󰖐",
            label: "Location",
            provider: "places"
        },
        "settings.clock": {
            icon: "󰅐",
            label: "Clock"
        },
        "settings.clock.panel": {
            icon: "󰕮",
            label: "Clock panel",
            action: () => menu.shell.timezone.open()
        },
        "settings.clock.timezone": {
            icon: "󰅐",
            label: "Timezone",
            provider: "zones"
        },
        "settings.media": {
            icon: menu.shell.media.icon,
            label: "Media"
        },
        "settings.media.panel": {
            icon: "󰕮",
            label: "Media panel",
            action: () => menu.shell.media.open()
        },
        "settings.media.playPause": {
            icon: "󰐎",
            label: "Play/Pause",
            ipc: "media playPause",
            enabled: menu.hasPlayer,
            action: () => menu.shell.media.service.runAction("playPause")
        },
        "settings.media.next": {
            icon: "󰒭",
            label: "Next",
            ipc: "media next",
            enabled: menu.hasPlayer,
            action: () => menu.shell.media.service.runAction("next")
        },
        "settings.media.previous": {
            icon: "󰒮",
            label: "Previous",
            ipc: "media previous",
            enabled: menu.hasPlayer,
            action: () => menu.shell.media.service.runAction("previous")
        },
        "settings.media.player": {
            icon: "󰌳",
            label: "Player",
            provider: "players"
        },
        "settings.audio": {
            icon: menu.shell.audio.icon,
            label: "Audio"
        },
        "settings.audio.panel": {
            icon: "󰕮",
            label: "Audio panel",
            action: () => menu.shell.audio.open()
        },
        "settings.audio.mute": {
            icon: menu.checkbox(!menu.shell.audio.muted),
            label: "Sound",
            ipc: "audio mute",
            action: () => menu.shell.audio.toggleMute()
        },
        "settings.audio.micMute": {
            icon: menu.checkbox(!menu.shell.audio.micMuted),
            label: "Microphone",
            ipc: "audio micMute",
            enabled: menu.shell.audio.sources.length > 0,
            action: () => menu.shell.audio.toggleMicMute()
        },
        "settings.audio.output": {
            icon: "󰓃",
            label: "Output",
            provider: "sinks"
        },
        "settings.display": {
            icon: "󰍹",
            label: "Display"
        },
        "settings.display.panel": {
            icon: "󰕮",
            label: "Display panel",
            action: () => menu.shell.display.open()
        },
        "settings.display.theme": {
            icon: "",
            label: "Theme"
        },
        "settings.display.theme.dark": {
            icon: menu.radio(menu.shell.dark),
            label: "Dark",
            action: () => menu.shell.setDark(true)
        },
        "settings.display.theme.light": {
            icon: menu.radio(!menu.shell.dark),
            label: "Light",
            action: () => menu.shell.setDark(false)
        },
        "settings.display.nightlight": {
            icon: "󰆔",
            label: "Nightlight"
        },
        "settings.display.nightlight.off": {
            icon: menu.radio(menu.shell.nightlight.mode === "off"),
            label: "Off",
            action: () => menu.shell.nightlight.setMode("off")
        },
        "settings.display.nightlight.auto": {
            icon: menu.radio(menu.shell.nightlight.mode === "auto"),
            label: "Auto",
            action: () => menu.shell.nightlight.setMode("auto")
        },
        "settings.display.nightlight.on": {
            icon: menu.radio(menu.shell.nightlight.mode === "on"),
            label: "On",
            action: () => menu.shell.nightlight.setMode("on")
        },
        "settings.display.textSize": {
            icon: "󰛖",
            label: "Text size",
            provider: "textScales"
        },
        "settings.display.mirror": {
            icon: "󰍺",
            label: "Mirror",
            provider: "mirrors"
        },
        "settings.display.wallpaper": {
            icon: "",
            label: "Wallpaper (workspace)",
            action: () => menu.shell.background.open("workspace")
        },
        "settings.display.backdrop": {
            icon: "",
            label: "Wallpaper (backdrop)",
            action: () => menu.shell.background.open("backdrop")
        },
        "settings.bluetooth": {
            icon: menu.shell.bluetoothService.icon,
            label: "Bluetooth"
        },
        "settings.bluetooth.panel": {
            icon: "󰕮",
            label: "Bluetooth panel",
            action: () => menu.shell.bluetooth.open()
        },
        "settings.bluetooth.power": {
            icon: menu.checkbox(menu.shell.bluetoothService.powered),
            label: "Bluetooth",
            enabled: menu.shell.bluetoothService.available,
            action: () => menu.shell.bluetoothService.togglePower()
        },
        "settings.bluetooth.devices": {
            icon: "󰂱",
            label: "Devices",
            provider: "devices"
        },
        "settings.bluetooth.pair": {
            icon: "󰐕",
            label: "Pair new device…",
            enabled: menu.shell.bluetoothService.available,
            action: () => Quickshell.execDetached(["xdg-terminal-exec", "bluetui"])
        },
        "settings.network": {
            icon: menu.shell.networkService.icon,
            label: "Network"
        },
        "settings.network.panel": {
            icon: "󰕮",
            label: "Network panel",
            action: () => menu.shell.network.open()
        },
        "settings.network.wifi": {
            icon: menu.checkbox(menu.shell.networkService.wifiEnabled),
            label: "Wi-Fi",
            enabled: menu.shell.networkService.wifiDevice !== null,
            action: () => menu.shell.networkService.toggleWifi()
        },
        // The scanner runs only while the panel is open.
        "settings.network.scan": {
            icon: "󰐷",
            label: "Scan",
            enabled: menu.shell.networkService.wifiEnabled,
            action: () => {
                menu.shell.network.open();
                menu.shell.networkService.scan();
            }
        },
        "settings.network.networks": {
            icon: "󰖩",
            label: "Wi-Fi networks",
            provider: "networks"
        },
        "settings.network.editor": {
            icon: "󰌘",
            label: "Connection settings…",
            action: () => Quickshell.execDetached(["nm-connection-editor"])
        },
        "settings.power": {
            icon: menu.shell.batteryService.icon,
            label: "Power"
        },
        "settings.power.panel": {
            icon: "󰕮",
            label: "Power panel",
            action: () => menu.shell.battery.open()
        },
        "settings.power.profile": {
            icon: "󰓅",
            label: "Profile"
        },
        "settings.power.profile.saver": menu.profileItem("power-saver", "Saver"),
        "settings.power.profile.balanced": menu.profileItem("balanced", "Balanced"),
        "settings.power.profile.performance": menu.profileItem("performance", "Performance"),
        "settings.notifications": {
            icon: "󰂚",
            label: "Notifications"
        },
        "settings.notifications.panel": {
            icon: "󰕮",
            label: "Notifications panel",
            action: () => menu.shell.notifications.showHistory()
        },
        "settings.notifications.clear": {
            icon: "󰃢",
            label: "Clear",
            action: () => menu.shell.notifications.clearHistory()
        },
        "settings.notifications.dnd": {
            icon: menu.checkbox(menu.shell.notifications.doNotDisturb),
            label: "DnD (Do not disturb)",
            action: () => menu.shell.notifications.setDoNotDisturb(!menu.shell.notifications.doNotDisturb)
        },
        "settings.keyboard": {
            icon: "󰌌",
            label: "Keyboard layout"
        },
        "settings.firmware": {
            icon: "󰚰",
            label: "Firmware"
        },
        "settings.firmware.panel": {
            icon: "󰕮",
            label: "Firmware panel",
            action: () => menu.shell.firmware.open()
        },
        "settings.firmware.refresh": {
            icon: "󰑐",
            label: "Check now",
            enabled: menu.shell.firmwareService.backends.length > 0,
            action: () => menu.shell.firmwareService.refresh()
        },
        "settings.firmware.copy": {
            icon: "󰆏",
            label: "Copy update command",
            provider: "firmwareUpdates"
        },
        "settings.firmware.page": {
            icon: "󰖟",
            label: "Open release page",
            provider: "firmwarePages"
        },
        "settings.doctor": {
            icon: "󰃤",
            label: "Doctor"
        },
        "settings.doctor.panel": {
            icon: "󰕮",
            label: "Doctor panel",
            action: () => menu.shell.doctor.open()
        },
        "settings.doctor.refresh": {
            icon: "󰑐",
            label: "Refresh",
            enabled: !menu.shell.doctorService.running,
            action: () => menu.shell.doctorService.refresh()
        },
        "settings.doctor.copy": {
            icon: "󰆏",
            label: "Copy report",
            enabled: menu.shell.doctorService.text !== "",
            action: () => menu.shell.doctorService.copyAll()
        },
        "settings.session": {
            icon: "󰐥",
            label: "Session"
        },
        "settings.session.lock": {
            icon: "",
            label: "Lock",
            ipc: "lock lock",
            action: () => menu.shell.lock.beginLock()
        },
        "settings.session.curtain": {
            icon: "󰛑",
            label: "Curtain",
            action: () => menu.shell.curtain.show()
        },
        "settings.session.idle": {
            icon: menu.checkbox(menu.shell.idle.enabled),
            label: "Idle locking",
            action: () => menu.shell.idle.setEnabled(!menu.shell.idle.enabled)
        },
        "settings.session.suspend": {
            icon: "󰒲",
            label: "Suspend",
            action: () => menu.run("systemctl suspend")
        },
        "settings.session.logout": {
            icon: "󰍃",
            label: "Logout",
            action: () => menu.run("uwsm stop")
        },
        "settings.session.reboot": {
            icon: "󰜉",
            label: "Reboot",
            action: () => menu.run("systemctl reboot")
        },
        "settings.session.shutdown": {
            icon: "󰐥",
            label: "Shutdown",
            action: () => menu.run("systemctl poweroff")
        }
    }, menu.layoutItems(), ...menu.shell.plugins.map(plugin => plugin.menuItems))

    readonly property bool hasPlayer: menu.shell.media.service.activePlayer !== null

    function checkbox(on) {
        return on ? "󰄲" : "󰄱";
    }
    function radio(on) {
        return on ? "󰐾" : "󰐽";
    }

    function profileItem(name, label) {
        const service = menu.shell.batteryService;
        return {
            icon: menu.radio(service.profile === name),
            label: label,
            enabled: service.profiles.indexOf(name) >= 0,
            action: () => service.setProfile(name)
        };
    }

    // Items, not a provider, so a root search finds a layout by name.
    function layoutItems() {
        const keyboard = menu.shell.keyboard;
        const items = {};
        keyboard.names.forEach((name, index) => {
            items["settings.keyboard." + index] = {
                icon: menu.radio(keyboard.index === index),
                label: name,
                action: () => keyboard.set(index)
            };
        });
        return items;
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    property string level: "root"

    cardWidth: wide ? 900 : 600
    cardHeight: wide ? 640 : 420

    property var binds: []

    // readBinds() points it at each config file in turn and reads it blocking.
    FileView {
        id: bindsFile
        preload: false
        blockAllReads: true
        printErrors: false
    }

    // Called on each opening, so edits to any included file show.
    function readBinds() {
        const home = Quickshell.env("HOME");
        const file = Ui.Compositor.configFile(home, Quickshell.env("NIRI_CONFIG"));
        binds = Ui.Compositor.readBinds(file, home, path => {
            bindsFile.path = path;
            bindsFile.reload();
            const text = bindsFile.text();
            return bindsFile.loaded ? text : null;
        });
    }

    property var emojis: []

    FileView {
        path: Ui.Paths.emoji
        printErrors: false
        // Shortcode-only entries (skin tones) have no name.
        onLoaded: menu.emojis = JSON.parse(text()).filter(e => e.name).map(e => ({
                    label: e.name,
                    icon: e.emoji,
                    image: "",
                    detail: "",
                    enabled: true,
                    entry: null,
                    action: () => Quickshell.execDetached(["wl-copy", e.emoji])
                }))
    }

    function iconUrl(icon) {
        const value = String(icon || "");
        if (value.length === 0)
            return "";
        if (value.startsWith("/"))
            return "file://" + value;
        if (value.startsWith("file://") || value.startsWith("image://"))
            return value;
        return Quickshell.iconPath(value, true);
    }

    function trayRows() {
        return TrayModel.sortItems(SystemTray.items.values).map(item => ({
                    label: TrayModel.labelFor(item),
                    icon: "󰘔",
                    image: TrayModel.themeIconName(item.icon) === "" ? (item.icon || "") : menu.iconUrl(TrayModel.themeIconName(item.icon)),
                    detail: item.tooltipTitle && item.title !== item.tooltipTitle ? item.tooltipTitle : "",
                    enabled: true,
                    entry: null,
                    trayItem: item
                }));
    }

    // Launch counts for frecency: apps keyed by entry.id, tree actions by their
    // menu id. Apps are built when entries load, not per keystroke: a first
    // icon-theme lookup costs ~25 ms per app.
    property var launchCounts: ({})
    property bool launchCountsLoaded: false
    readonly property var baseApps: DesktopEntries.applications.values.filter(entry => !entry.noDisplay).map(entry => ({
                label: entry.name,
                icon: "󰀻",
                image: menu.iconUrl(entry.icon),
                detail: "",
                enabled: true,
                entry: entry
            }))
    readonly property var apps: baseApps.slice().sort((a, b) => a.label.localeCompare(b.label))

    function recordLaunch(id) {
        launchCounts = Object.assign({}, launchCounts, {
            [id]: (Number(launchCounts[id]) || 0) + 1
        });
        if (launchCountsLoaded)
            launchCountsFile.setText(JSON.stringify({
                version: 1,
                counts: launchCounts
            }) + "\n");
    }

    FileView {
        id: launchCountsFile
        path: Ui.Paths.state + "/launch-counts.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                var parsed = JSON.parse(String(text() || ""));
                menu.launchCounts = parsed.counts || {};
            } catch (error) {
                menu.launchCounts = {};
            }
            menu.launchCountsLoaded = true;
        }
        onLoadFailed: menu.launchCountsLoaded = true
    }

    Component.onCompleted: launchCountsFile.reload()

    function appRows(detail) {
        return apps.map(row => Object.assign({}, row, {
                detail: detail || ""
            }));
    }

    function placeRows() {
        const service = menu.shell.weatherService;
        return PlacesModel.places.map(place => ({
                    label: place.name,
                    icon: menu.radio(service.latitude === place.latitude && service.longitude === place.longitude),
                    image: "",
                    detail: place.country,
                    enabled: true,
                    entry: null,
                    action: () => service.setLocation(place.latitude, place.longitude, place.name)
                }));
    }

    // Setting the zone goes through polkit, so the agent may ask before it lands.
    function zoneRows() {
        const service = menu.shell.timezoneService;
        return ZonesModel.zones.map(zone => ({
                    label: zone.name,
                    icon: menu.radio(service.zone === zone.zone),
                    image: "",
                    detail: zone.zone,
                    enabled: true,
                    entry: null,
                    action: () => service.setZone(zone.zone)
                }));
    }

    function playerRows() {
        const service = menu.shell.media.service;
        const active = service.playerKey(service.activePlayer);
        return service.sourcePlayers.map(player => ({
                    label: MediaModel.labelFor(player),
                    icon: menu.radio(service.playerKey(player) === active),
                    detail: MediaModel.detailFor(player),
                    enabled: true,
                    action: () => service.selectPlayer(service.playerKey(player))
                }));
    }

    function sinkRows() {
        const audio = menu.shell.audio;
        return audio.sinks.map(node => ({
                    label: audio.label(node),
                    icon: menu.radio(node === audio.sink),
                    detail: "",
                    enabled: true,
                    action: () => audio.setDefault(node)
                }));
    }

    function textScaleRows() {
        return menu.shell.display.textScales.map(value => ({
                    label: Math.round(value * 100) + "%",
                    icon: menu.radio(Math.abs(value - menu.shell.textScale) < 0.01),
                    detail: "",
                    enabled: true,
                    action: () => menu.shell.setTextScale(value)
                }));
    }

    // The mirror rows' source. Only the compositor knows it, so each open queries it.
    property string focusedOutput: ""

    Process {
        id: focusedOutputQuery
        command: Ui.Compositor.outputs()
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const monitor = Ui.Compositor.focusedMonitor(text);
                menu.focusedOutput = monitor ? monitor.name : "";
            }
        }
    }

    // Targets for the focused output; Off stops every mirror.
    function mirrorRows() {
        const mirror = menu.shell.mirror;
        const source = menu.focusedOutput;
        return [
            {
                label: "Off",
                icon: menu.radio(!mirror.active),
                detail: "",
                enabled: !mirror.busy,
                action: () => mirror.stopAll()
            }
        ].concat(Quickshell.screens.filter(screen => source && screen.name !== source).map(screen => {
            const current = mirror.sourceOf(screen.name);
            return {
                label: screen.name,
                icon: menu.checkbox(current === source),
                detail: current && current !== source ? "shows " + current : "",
                enabled: !mirror.busy && (current === source || mirror.canMirror(source, screen.name)),
                action: () => current === source ? mirror.stop(screen.name) : mirror.start(source, screen.name)
            };
        }));
    }

    function deviceRows() {
        const service = menu.shell.bluetoothService;
        return (service.powered ? service.devices : []).map(device => ({
                    label: BluetoothModel.deviceName(device),
                    icon: menu.checkbox(device.connected),
                    detail: service.deviceStatus(device),
                    enabled: true,
                    action: () => service.toggleConnection(device)
                }));
    }

    function firmwareRows() {
        const service = menu.shell.firmwareService;
        return service.updates.map(update => ({
                    label: update.name,
                    icon: "󰆏",
                    detail: FirmwareModel.detail(update),
                    enabled: true,
                    action: () => service.copyCommand(update.id)
                }));
    }

    function firmwarePageRows() {
        const service = menu.shell.firmwareService;
        return service.updates.filter(update => update.url !== "").map(update => ({
                    label: update.name,
                    icon: "󰖟",
                    detail: update.url,
                    enabled: true,
                    action: () => service.openPage(update.id)
                }));
    }

    // Known networks only: the scanner runs while the Network panel is open.
    function networkRows() {
        const service = menu.shell.networkService;
        return (service.wifiEnabled ? service.wifiNetworks : []).map(network => ({
                    label: network.name,
                    icon: menu.radio(network.connected),
                    detail: service.wifiStatus(network),
                    enabled: true,
                    action: () => service.activate(network)
                }));
    }

    IpcHandler {
        target: "menu"

        function toggle(): void {
            menu.toggle(true);
        }
        function open(): void {
            menu.open("root");
        }
        function close(): void {
            menu.close();
        }
        function level(id: string): void {
            menu.open(id);
        }
        function popup(id: string): void {
            menu.open(id);
        }
    }

    readonly property var providers: ({
            binds: function () {
                return menu.binds;
            },
            tray: function () {
                return menu.trayRows();
            },
            apps: function (detail) {
                return menu.appRows(detail);
            },
            places: function () {
                return menu.placeRows();
            },
            zones: function () {
                return menu.zoneRows();
            },
            emoji: function () {
                return menu.emojis;
            },
            players: function () {
                return menu.playerRows();
            },
            sinks: function () {
                return menu.sinkRows();
            },
            textScales: function () {
                return menu.textScaleRows();
            },
            mirrors: function () {
                return menu.mirrorRows();
            },
            devices: function () {
                return menu.deviceRows();
            },
            networks: function () {
                return menu.networkRows();
            },
            firmwareUpdates: function () {
                return menu.firmwareRows();
            },
            firmwarePages: function () {
                return menu.firmwarePageRows();
            }
        })

    // Launcher rows shaped like QsMenuEntry, for a MenuCard; keep filters the
    // target's own rows; counts orders them by frecency. A keybinding has no
    // action and is there to read.
    function cardRows(target, keep, query, counts) {
        const rows = Model.rowsFor(menu.items, target, query, menu.providers, counts, menu.binds).filter(keep || (() => true)).map(row => {
            const run = row.trayItem || row.entry || row.action ? () => menu.launch(row) : null;
            return {
                text: row.label,
                glyph: row.icon,
                image: row.image || "",
                detail: row.detail || "",
                keys: row.chord !== undefined ? Ui.Compositor.keycaps(row.chord) : [],
                enabled: row.enabled && (row.submenu || !!run || row.chord !== undefined),
                isSeparator: false,
                hasChildren: row.submenu === true,
                rows: row.submenu ? childQuery => menu.cardRows(row.id, null, childQuery, counts) : undefined,
                triggered: run,
                key: row.id
            };
        });
        // Sets a node's panel row apart from its actions.
        if (rows[0]?.key === target + ".panel")
            rows.splice(1, 0, menu.separator);
        return rows;
    }

    readonly property var separator: ({
            isSeparator: true,
            enabled: true
        })

    // Card rows for the context menu, in the tree's order. Its top level opens
    // the launcher where a node opens its panel.
    function contextRows(target, keep, query) {
        const rows = menu.cardRows(target, keep, query);
        if (target === "root" && !query)
            rows.unshift({
                text: "Launcher",
                glyph: "\u{F0349}",
                keys: menu.toggleKeys,
                enabled: true,
                isSeparator: false,
                hasChildren: false,
                triggered: () => menu.open("root"),
                key: "root.panel"
            }, menu.separator);
        return rows;
    }

    property string popped: ""

    // Opens target as a context menu hanging from button on output; without them
    // it centers on the focused output. Opening the shown one again on its output
    // closes it.
    function popup(target, output, button, keep) {
        focusedOutputQuery.running = true;
        if (contextMenu.shown && popped === target && (!output || contextMenu.screen?.name === output)) {
            contextMenu.close();
            return;
        }
        popped = target;
        readBinds();
        contextMenu.popup({
            rows: query => menu.contextRows(target, keep, query),
            title: menu.items[target]?.label ?? ""
        }, output, button ? () => {
            const point = button.mapToItem(null, 0, 0);
            return {
                below: true,
                x: point.x,
                width: button.width
            };
        } : null);
    }

    readonly property var toggleKeys: Ui.Compositor.keycaps(Model.chordFor({
        ipc: "menu toggle"
    }, menu.binds))

    // Set while the menu toggle bind opened the palette.
    property bool keyOpened: false
    onShownChanged: if (!shown)
        keyOpened = false

    readonly property string breadcrumb: level === "root" ? "Launcher" : level.split(".").map((part, index, parts) => menu.items[parts.slice(0, index + 1).join(".")].label).join(" › ")

    readonly property bool wide: level !== "root" && menu.items[level].provider === "binds"

    function open(target) {
        if (shell && shell.registerPanel)
            shell.registerPanel(menu);
        if (shell && shell.claimPanel)
            shell.claimPanel(menu);
        if (!shown)
            readBinds();
        focusedOutputQuery.running = true;
        level = target;
        card.clear();
        shown = true;
        card.focusSearch();
        Qt.callLater(card.selectFirst);
    }

    // byKey: the menu toggle bind called it.
    function toggle(byKey) {
        if (shown) {
            close();
            return;
        }
        open("root");
        keyOpened = byKey === true;
    }

    function back() {
        if (level === "root")
            close();
        else
            open(Model.parentLevel(level));
    }

    function launch(row) {
        if (row.trayItem) {
            if (row.trayItem.hasMenu)
                menu.shell.tray.openFor(row.trayItem);
            else
                row.trayItem.activate();
        } else if (row.entry) {
            menu.recordLaunch(row.entry.id);
            // Keep launched apps out of Quickshell's service scope.
            Quickshell.execDetached(["uwsm-app", "--", row.entry.id + ".desktop"]);
        } else {
            // Provider rows (places, sinks, ...) have no stable id to key a count by.
            if (row.id)
                menu.recordLaunch(row.id);
            row.action();
        }
    }

    Text {
        color: menu.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: menu.breadcrumb
    }

    Ui.MenuCard {
        id: card
        width: parent.width
        height: parent.height - y
        shell: menu.shell
        rows: menu.cardRows(menu.level, null, card.query, menu.launchCounts)
        placeholder: menu.level === "root" ? "Search…" : "Filter " + menu.items[menu.level].label.toLowerCase() + "…"
        openerKeys: menu.keyOpened ? menu.toggleKeys : []
        fontSize: 14
        rowHeight: 28
        // The panel fixes the width; Emoji has thousands of rows.
        maxWidth: 0

        onOpenRequested: row => {
            menu.open(row.key);
            card.settle();
        }
        // A row without an action (a keybinding) is there to read.
        onRunRequested: row => {
            if (!row.triggered)
                return;
            menu.close();
            row.triggered();
        }
        onBackRequested: menu.back()
        onCloseRequested: menu.close()
    }
}
