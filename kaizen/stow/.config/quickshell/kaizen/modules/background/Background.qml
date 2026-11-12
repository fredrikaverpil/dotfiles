import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../../Ui" as Ui
import "WallpaperModel.js" as Model

Scope {
    id: background

    required property var shell

    function open(slot) {
        picker.open(slot || "workspace");
    }
    function close() {
        picker.close();
    }
    function toggle(slot) {
        picker.shown ? picker.close() : picker.open(slot || "workspace");
    }

    readonly property string shownWallpaperDir: "~/Pictures/Wallpapers"
    readonly property string wallpaperDir: Quickshell.env("HOME") + shownWallpaperDir.substring(1)
    readonly property string thumbDir: Ui.Paths.cache + "/wallpaper-thumbs"
    readonly property string statePath: Ui.Paths.state + "/wallpaper.json"
    property bool stateLoaded: false
    property list<string> wallpapers: []
    readonly property int columns: 6
    // Header rows ({header, label}) and image rows ({start, count}); start
    // indexes `wallpapers`, which is sorted so each folder is contiguous.
    property var rows: []
    property var rowOfIndex: []
    // Wallpapers the current thumbnail pass has reached, generated or not.
    property int thumbsDone: 0
    readonly property bool thumbsRunning: thumbs.running
    property string darkPick: ""
    property string lightPick: ""
    property string backdropDarkPick: ""
    property string backdropLightPick: ""

    // Which of the two layers the picker is currently editing.
    property string slot: "workspace"
    property string preview: ""

    readonly property string wallpaper: shell.dark ? darkPick : lightPick
    readonly property string backdrop: shell.dark ? backdropDarkPick : backdropLightPick
    readonly property string shownWallpaper: slot === "workspace" && preview ? preview : wallpaper
    readonly property string shownBackdrop: slot === "backdrop" && preview ? preview : backdrop

    Timer {
        id: previewDelay
        interval: 250
        onTriggered: background.preview = picker.shown ? pickerView.selected : ""
    }

    Connections {
        target: picker
        function onShownChanged() {
            if (picker.shown) {
                previewDelay.restart();
            } else {
                previewDelay.stop();
                background.preview = "";
            }
        }
    }

    function currentPick() {
        return slot === "backdrop" ? backdrop : wallpaper;
    }

    // A URL. Qt.md5 of the path matches `printf %s <path> | md5sum`, so the
    // generator below and the grid derive the same name without sharing a list.
    function thumbFor(path) {
        return "file://" + background.thumbDir + "/" + Qt.md5(path) + ".jpg";
    }

    function buildRows() {
        const layout = Model.layout(wallpapers, wallpaperDir, columns);
        rows = layout.rows;
        rowOfIndex = layout.rowOfIndex;
    }

    function saveState() {
        if (!stateLoaded)
            return;
        stateFile.setText(JSON.stringify({
            version: 1,
            wallpaperDark: darkPick,
            wallpaperLight: lightPick,
            backdropDark: backdropDarkPick,
            backdropLight: backdropLightPick
        }) + "\n");
    }

    function setWallpaper(path) {
        if (slot === "backdrop") {
            if (shell.dark)
                backdropDarkPick = path;
            else
                backdropLightPick = path;
        } else if (shell.dark) {
            darkPick = path;
        } else {
            lightPick = path;
        }
        saveState();
    }

    Component.onCompleted: {
        stateLoaded = true;
        stateFile.reload();
    }

    Process {
        id: scan
        running: true
        // Skips macOS resource-fork stubs and the empty files a failed download
        // leaves behind; neither is an image.
        command: ["find", background.wallpaperDir, "-type", "f", "-iregex", ".*\\.\\(png\\|jpg\\|jpeg\\|webp\\)", "!", "-name", "._*", "!", "-size", "0"]
        stdout: StdioCollector {
            onStreamFinished: {
                background.wallpapers = Model.sorted(text.trim().split("\n").filter(l => l.length > 0), background.wallpaperDir);
                background.buildRows();
                if (!thumbs.running)
                    thumbs.running = true;
            }
        }
    }

    // The grid renders thumbnails because most of the library is PNG, which Qt
    // decodes in full before scaling. Each pass refreshes the mtime of every
    // thumbnail still wanted, so thumbnails of removed wallpapers age out and
    // nothing else has to prune the cache.
    Process {
        id: thumbs
        onRunningChanged: if (thumbs.running)
            background.thumbsDone = 0
        command: ["sh", "-c", `
            set -e
            mkdir -p "$2"
            find "$1" -type f -iregex '.*\\.\\(png\\|jpg\\|jpeg\\|webp\\)' ! -name '._*' ! -size 0 | while IFS= read -r f; do
                t="$2/$(printf %s "$f" | md5sum | cut -d' ' -f1).jpg"
                if [ -e "$t" ]; then
                    touch "$t"
                else
                    magick "$f" -auto-orient -thumbnail '480x480>' -quality 82 "$t" || :
                fi
                echo .
            done
            find "$2" -type f -mtime +30 -delete
        `, "sh", background.wallpaperDir, background.thumbDir]
        // One line per wallpaper reached, counted for the picker's header.
        stdout: SplitParser {
            onRead: background.thumbsDone++
        }
    }

    FileView {
        id: stateFile
        path: background.statePath
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(String(text() || ""));
                background.darkPick = parsed.wallpaperDark || "";
                background.lightPick = parsed.wallpaperLight || "";
                background.backdropDarkPick = parsed.backdropDark || "";
                background.backdropLightPick = parsed.backdropLight || "";
            } catch (error) {
                // No readable state: the picks stay empty and the views fall back.
            }
            background.stateLoaded = true;
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            background.toggle("workspace");
        }
        function open(): void {
            picker.open("workspace");
        }
        function openBackdrop(): void {
            picker.open("backdrop");
        }
        function close(): void {
            picker.close();
        }
        function rescan(): void {
            scan.running = true;
        }
        function set(path: string): void {
            background.setWallpaper(path);
        }
    }

    // Wallpaper surface. The backdrop one, where the compositor places one
    // (Compositor.placesBackdrop), is pulled behind the workspaces by a layer
    // rule matching its namespace.
    component Wall: PanelWindow {
        required property var modelData
        property string src: ""

        screen: modelData
        WlrLayershell.layer: WlrLayer.Background
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: background.shell.palette.dim
                }
                GradientStop {
                    position: 1.0
                    color: background.shell.palette.bg
                }
            }
        }

        Item {
            id: wall
            anchors.fill: parent
            readonly property string url: src ? "file://" + src : ""

            function swap() {
                if (!url) {
                    under.source = "";
                    over.source = "";
                    return;
                }
                if (String(over.source) === url)
                    return;
                fade.enabled = false;
                over.opacity = 0;
                fade.enabled = true;

                under.source = over.source;
                over.source = url;
                over.opacity = 1;
            }

            Image {
                id: loader
                source: wall.url
                asynchronous: true
                visible: false
                onStatusChanged: if (status === Image.Ready)
                    wall.swap()
                onSourceChanged: if (status === Image.Ready)
                    wall.swap()
                Component.onCompleted: if (status === Image.Ready)
                    wall.swap()
            }

            Image {
                id: under
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
            }

            Image {
                id: over
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                opacity: 0
                Behavior on opacity {
                    id: fade
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Variants {
        model: Ui.Compositor.placesBackdrop ? background.shell.screens : []

        Wall {
            WlrLayershell.namespace: "quickshell-backdrop"
            src: background.shownBackdrop
        }
    }

    Variants {
        model: background.shell.screens

        Wall {
            WlrLayershell.namespace: "quickshell-wallpaper"
            src: background.shownWallpaper
        }
    }

    Ui.Panel {
        id: picker
        shell: background.shell
        cardWidth: pickerView.cardWidth
        cardHeight: pickerView.cardHeight
        cardPadding: pickerView.cardPadding
        keyNavigation: pickerView.keyNavigation

        function open(slot) {
            if (slot === "backdrop" && !Ui.Compositor.placesBackdrop)
                return;
            background.slot = slot || "workspace";
            scan.running = true;
            if (background.shell && background.shell.registerPanel)
                background.shell.registerPanel(picker);
            if (background.shell && background.shell.claimPanel)
                background.shell.claimPanel(picker);
            shown = true;
            pickerView.reset();
        }

        PickerView {
            id: pickerView
            shell: background.shell
            service: background
            onSelectedChanged: previewDelay.restart()
            onCloseRequested: picker.close()
        }
    }
}
