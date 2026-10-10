import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

import "ShellModel.js" as Model
import "Ui" as Ui

import "modules/background" as Background
import "modules/bar" as Bar
import "modules/lock" as Lock
import "modules/menu" as Menu
import "modules/notifications" as Notifications
import "modules/panels/audio" as Audio
import "modules/panels/battery" as Battery
import "modules/panels/bluetooth" as Bluetooth
import "modules/panels/clipboard" as Clipboard
import "modules/panels/media" as Media
import "modules/panels/display" as Display
import "modules/panels/firmware" as Firmware
import "modules/panels/doctor" as Doctor
import "modules/panels/network" as Network
import "modules/panels/recording" as Recording
import "modules/panels/timezone" as Timezone
import "modules/panels/tray" as Tray
import "modules/panels/weather" as Weather
import "modules/polkit" as Polkit
import "modules/curtain" as Curtain
import "modules/services/battery" as BatteryService
import "modules/services/bluetooth" as BluetoothService
import "modules/services/brightness" as Brightness
import "modules/services/clipboard" as ClipboardService
import "modules/services/firmware" as FirmwareService
import "modules/services/doctor" as DoctorService
import "modules/services/idle" as Idle
import "modules/services/keyboard" as Keyboard
import "modules/services/media" as MediaService
import "modules/services/mirror" as Mirror
import "modules/services/network" as NetworkService
import "modules/services/nightlight" as Nightlight
import "modules/services/recording" as RecordingService
import "modules/services/system" as SystemService
import "modules/services/timezone" as TimezoneService
import "modules/services/weather" as WeatherService

ShellRoot {
    id: root

    readonly property alias menu: menu
    readonly property alias background: background
    readonly property alias notifications: notifications
    readonly property alias nightlight: nightlight
    readonly property alias idle: idle
    readonly property alias lock: lock
    readonly property alias keyboard: keyboard
    readonly property alias media: media
    readonly property alias display: display
    readonly property alias brightness: brightness
    readonly property alias mirror: mirror
    readonly property alias curtain: curtain
    readonly property alias network: network
    readonly property alias networkService: networkService
    readonly property alias bluetooth: bluetooth
    readonly property alias bluetoothService: bluetoothService
    readonly property alias audio: audio
    readonly property alias battery: battery
    readonly property alias batteryService: batteryService
    readonly property alias tray: tray
    readonly property alias recording: recording
    readonly property alias recordingService: recordingService
    readonly property alias weather: weather
    readonly property alias weatherService: weatherService
    readonly property alias systemService: systemService
    readonly property alias clipboard: clipboard
    readonly property alias timezone: timezone
    readonly property alias timezoneService: timezoneService
    readonly property alias firmware: firmware
    readonly property alias firmwareService: firmwareService
    readonly property alias doctor: doctor
    readonly property alias doctorService: doctorService

    readonly property int barHeight: Math.round(32 * textScale)
    property var panels: []

    // Ui.Plugin instances, in name order; one that fails to load is left out.
    property var plugins: []

    function loadPlugins() {
        const loaded = [];
        for (let i = 0; i < pluginLoaders.count; i++) {
            const plugin = (pluginLoaders.objectAt(i) as Loader)?.item;
            if (plugin)
                loaded.push(plugin);
        }
        plugins = loaded;
    }

    // Both plugin dirs listed, so a plugin's dir is known before it loads.
    property bool pluginDirsListed: false

    function listPluginDirs() {
        if (shellPluginDirs.status === FolderListModel.Ready && configPluginDirs.status === FolderListModel.Ready)
            pluginDirsListed = true;
    }

    // The Plugin.qml under the one plugin dir named name; "" when neither or
    // both have it.
    function pluginSource(name) {
        const dirs = [shellPluginDirs, configPluginDirs].filter(model => {
            for (let i = 0; i < model.count; i++) {
                if (model.get(i, "fileName") === name)
                    return true;
            }
            return false;
        });
        return dirs.length === 1 ? String(dirs[0].folder) + "/" + name + "/Plugin.qml" : "";
    }

    // Each <name>.jsonc enables plugins/<name>/Plugin.qml, in this tree or in
    // Ui.Paths.config, and holds its config.
    FolderListModel {
        id: pluginFiles
        folder: "file://" + Ui.Paths.config + "/plugins"
        nameFilters: ["*.jsonc"]
        showDirs: false
    }

    FolderListModel {
        id: shellPluginDirs
        folder: "file://" + Quickshell.shellPath("plugins")
        showFiles: false
        onStatusChanged: root.listPluginDirs()
    }

    FolderListModel {
        id: configPluginDirs
        folder: "file://" + Ui.Paths.config + "/plugins"
        showFiles: false
        onStatusChanged: root.listPluginDirs()
    }

    Instantiator {
        id: pluginLoaders
        active: root.pluginDirsListed
        model: pluginFiles
        onObjectAdded: root.loadPlugins()
        onObjectRemoved: root.loadPlugins()

        delegate: Loader {
            required property string fileBaseName
            Component.onCompleted: {
                const source = root.pluginSource(fileBaseName);
                if (source)
                    setSource(source, {
                        shell: root
                    });
            }
            onLoaded: root.loadPlugins()
        }
    }

    // Quickshell watches only files shell.qml imports; plugins load by path.
    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.reload(false);
        }
    }

    function registerPanel(panel) {
        if (panel && panels.indexOf(panel) < 0)
            panels = panels.concat([panel]);
    }

    function claimPanel(panel) {
        for (const candidate of panels) {
            if (candidate && candidate !== panel && candidate.shown)
                candidate.close();
        }
    }

    property bool dark: true
    property real textScale: 1
    // zenbones.nvim: extras/ghostty/zenbones_{dark,light}.
    readonly property var darkPalette: ({
            bg: "#1C1917",
            fg: "#B4BDC3",
            sel: "#3D4042",
            dim: "#403833",
            off: "#6E6864",
            rose: "#DE6E7C",
            leaf: "#819B69",
            wood: "#B77E64",
            water: "#6099C0",
            blossom: "#B279A7",
            sky: "#66A5AD"
        })
    readonly property var lightPalette: ({
            bg: "#F0EDEC",
            fg: "#2C363C",
            sel: "#CBD9E3",
            dim: "#CFC1BA",
            off: "#8F857D",
            rose: "#A8334C",
            leaf: "#4F6C31",
            wood: "#944927",
            water: "#286486",
            blossom: "#88507D",
            sky: "#3B8992"
        })
    readonly property var palette: dark ? darkPalette : lightPalette

    // KConfig needs --notify before the dconf palette change or running Dolphin keeps cached view colours.
    function kdeglobalsWrite(on) {
        return Model.kdeglobalsWrite(on, darkPalette, lightPalette);
    }

    function writeKdeglobals() {
        kdeglobals.command = ["sh", "-c", kdeglobalsWrite(root.dark)];
        kdeglobals.running = true;
    }

    function setDark(on) {
        const scheme = on ? "prefer-dark" : "prefer-light";
        const gtk = on ? "Adwaita-dark" : "Adwaita";
        write.command = ["sh", "-c", kdeglobalsWrite(on) + "dconf write /org/gnome/desktop/interface/color-scheme \"'" + scheme + "'\"; " + "dconf write /org/gnome/desktop/interface/gtk-theme \"'" + gtk + "'\""];
        write.running = true;
    }

    // Not palette: onDarkChanged runs before palette re-evaluates.
    function writeNiriColors() {
        niriColors.setText(Model.niriColors(dark ? darkPalette : lightPalette));
    }

    onDarkChanged: {
        writeKdeglobals();
        writeNiriColors();
    }

    Process {
        id: write
    }
    Process {
        id: kdeglobals
    }

    // Included by niri/config.kdl.
    FileView {
        id: niriColors
        path: Ui.Paths.state + "/niri-colors.kdl"
        atomicWrites: true
        printErrors: false
    }

    function setTextScale(value) {
        const scale = Model.textScale(value);
        if (scale === null)
            return;
        textScale = scale;
        textScaleWrite.command = ["dconf", "write", "/org/gnome/desktop/interface/text-scaling-factor", scale.toFixed(2), // GVariant double; "2" would store an int32 that GSettings ignores.
        ];
        textScaleWrite.running = true;
    }

    function updateTextScale(value) {
        const scale = Model.observedTextScale(value);
        if (scale !== null)
            textScale = scale;
    }

    Process {
        id: textScaleWrite
    }

    IpcHandler {
        target: "theme"

        function toggle(): void {
            root.setDark(!root.dark);
        }
        function dark(): void {
            root.setDark(true);
        }
        function light(): void {
            root.setDark(false);
        }
    }

    Process {
        running: true
        command: ["dconf", "watch", "/org/gnome/desktop/interface/"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("prefer-dark") >= 0)
                    root.dark = true;
                else if (line.indexOf("prefer-light") >= 0)
                    root.dark = false;
            }
        }
    }

    Process {
        running: true
        command: ["dconf", "read", "/org/gnome/desktop/interface/color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.dark = text.indexOf("prefer-light") < 0;
                root.writeKdeglobals();
                root.writeNiriColors();
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
        curtainService: curtain
    }

    Curtain.Service {
        id: curtain
        shell: root
        brightnessService: brightness
    }

    Keyboard.Service {
        id: keyboard
    }

    Nightlight.Service {
        id: nightlight
        shell: root
        latitude: weatherService.latitude
        longitude: weatherService.longitude
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

    Brightness.Service {
        id: brightness
    }

    Mirror.Service {
        id: mirror
    }

    Display.Panel {
        id: display
        shell: root
    }

    BatteryService.Service {
        id: batteryService
    }

    Battery.Panel {
        id: battery
        shell: root
        service: batteryService
    }

    NetworkService.Service {
        id: networkService
    }

    Network.Panel {
        id: network
        shell: root
        service: networkService
    }

    BluetoothService.Service {
        id: bluetoothService
    }

    Bluetooth.Panel {
        id: bluetooth
        shell: root
        service: bluetoothService
    }

    Audio.Panel {
        id: audio
        shell: root
    }

    Audio.Osd {
        shell: root
        audio: audio
    }

    Tray.Panel {
        id: tray
        shell: root
    }

    RecordingService.Service {
        id: recordingService
        barHeight: root.barHeight
    }

    Recording.Panel {
        id: recording
        shell: root
        service: recordingService
    }

    Recording.Countdown {
        shell: root
        service: recordingService
    }

    Recording.Selector {
        shell: root
        service: recordingService
    }

    WeatherService.Service {
        id: weatherService
    }

    Weather.Panel {
        id: weather
        shell: root
        service: weatherService
    }

    SystemService.Service {
        id: systemService
    }

    ClipboardService.Service {
        id: clipboardService
    }

    Clipboard.Panel {
        id: clipboard
        shell: root
        service: clipboardService
    }

    TimezoneService.Service {
        id: timezoneService
    }

    Timezone.Panel {
        id: timezone
        shell: root
        service: timezoneService
    }

    FirmwareService.Service {
        id: firmwareService
    }

    Firmware.Panel {
        id: firmware
        shell: root
        service: firmwareService
    }

    DoctorService.Service {
        id: doctorService
    }

    Doctor.Panel {
        id: doctor
        shell: root
        service: doctorService
    }

    // Shows a launcher level hanging from a bar button.
    Ui.ContextMenu {
        id: launcherMenu
        shell: root
    }

    Menu.Menu {
        id: menu
        shell: root
        contextMenu: launcherMenu
    }

    Bar.Bar {
        shell: root
    }
}
