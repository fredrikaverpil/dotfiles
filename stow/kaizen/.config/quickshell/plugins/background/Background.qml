import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../../Ui" as Ui

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

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string thumbDir: Ui.Paths.cache + "/wallpaper-thumbs"
    readonly property string statePath: Ui.Paths.state + "/wallpaper.json"
    property bool stateLoaded: false
    property list<string> wallpapers: []
    readonly property int columns: 4
    // Header rows ({header, label}) and image rows ({start, count}); start
    // indexes `wallpapers`, which is sorted so each folder is contiguous.
    property var rows: []
    property var rowOfIndex: []
    // Wallpapers the current thumbnail pass has reached, generated or not.
    property int thumbsDone: 0
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
        onTriggered: background.preview = picker.shown && grid.sel >= 0 ? (background.wallpapers[grid.sel] || "") : ""
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

    // Qt.md5 of the path matches `printf %s <path> | md5sum`, so the generator
    // below and the grid derive the same name without sharing a list.
    function thumbFor(path) {
        return background.thumbDir + "/" + Qt.md5(path) + ".jpg";
    }

    // Folder of a wallpaper relative to wallpaperDir; "" for the root.
    function dirOf(path) {
        const rel = path.slice(wallpaperDir.length + 1);
        const i = rel.lastIndexOf("/");
        return i < 0 ? "" : rel.slice(0, i);
    }

    function buildRows() {
        const out = [];
        const rowOf = [];
        let dir = null;
        wallpapers.forEach((path, i) => {
            const d = dirOf(path);
            if (d !== dir) {
                dir = d;
                out.push({
                    header: true,
                    label: d || "Wallpapers"
                });
            }
            let row = out[out.length - 1];
            if (row.header || row.count === columns) {
                row = {
                    header: false,
                    start: i,
                    count: 0
                };
                out.push(row);
            }
            row.count++;
            rowOf[i] = out.length - 1;
        });
        rows = out;
        rowOfIndex = rowOf;
        Qt.callLater(grid.reveal);
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
                background.wallpapers = text.trim().split("\n").filter(l => l.length > 0).sort((a, b) => {
                    const da = background.dirOf(a), db = background.dirOf(b);
                    if (da !== db)
                        return da < db ? -1 : 1;
                    return a < b ? -1 : a > b ? 1 : 0;
                });
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

    // Wallpaper surface. The backdrop one is pulled behind the workspaces by a
    // niri layer rule matching its namespace.
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
        model: Quickshell.screens

        Wall {
            WlrLayershell.namespace: "quickshell-backdrop"
            src: background.shownBackdrop
        }
    }

    Variants {
        model: Quickshell.screens

        Wall {
            WlrLayershell.namespace: "quickshell-wallpaper"
            src: background.shownWallpaper
        }
    }

    Ui.Panel {
        id: picker
        shell: background.shell
        cardWidth: 840
        cardHeight: 540

        function open(slot) {
            background.slot = slot || "workspace";
            scan.running = true;
            if (background.shell && background.shell.registerPanel)
                background.shell.registerPanel(picker);
            if (background.shell && background.shell.claimPanel)
                background.shell.claimPanel(picker);
            shown = true;
            grid.sel = Math.max(0, background.wallpapers.indexOf(background.currentPick()));
            grid.forceActiveFocus();
        }

        function choose() {
            const path = background.wallpapers[grid.sel];
            if (path)
                background.setWallpaper(path);
            close();
        }

        function clear() {
            background.setWallpaper("");
            close();
        }

        Item {
            width: parent.width
            height: Math.max(title.height, clearButton.height)

            Text {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                color: background.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 15
                text: "Wallpaper (" + background.slot + ") · " + (background.shell.dark ? "dark" : "light") + (thumbs.running ? " · thumbnails " + background.thumbsDone + "/" + background.wallpapers.length : "")
            }

            Rectangle {
                id: clearButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.width + 20
                height: clearLabel.height + 10
                radius: 4
                activeFocusOnTab: true
                color: activeFocus ? background.shell.palette.dim : "transparent"
                border.color: activeFocus ? background.shell.palette.fg : background.shell.palette.dim
                border.width: 1

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    color: background.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    text: "󰅖 Clear"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: picker.clear()
                }

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape)
                        picker.close();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                        picker.clear();
                    else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up)
                        grid.forceActiveFocus();
                    else
                        return;
                    event.accepted = true;
                }
            }
        }

        ListView {
            id: grid
            width: parent.width
            height: parent.height - y
            clip: true
            focus: true
            activeFocusOnTab: true
            keyNavigationEnabled: false
            // Index into background.wallpapers; the view's own currentIndex
            // counts rows, headers included.
            property int sel: 0
            readonly property real cellWidth: (width - 16) / background.columns
            readonly property real cellHeight: cellWidth * 9 / 16
            model: background.rows
            onSelChanged: {
                previewDelay.restart();
                reveal();
            }

            // Keeps a section's header in view when its first row is selected.
            function reveal() {
                let r = background.rowOfIndex[sel];
                if (r === undefined)
                    return;
                if (background.rows[r - 1] && background.rows[r - 1].header)
                    r--;
                positionViewAtIndex(r, ListView.Contain);
            }

            // Moves one image row up or down, skipping headers.
            function step(dir) {
                const r = background.rowOfIndex[sel];
                if (r === undefined)
                    return false;
                let t = r + dir;
                while (background.rows[t] && background.rows[t].header)
                    t += dir;
                const row = background.rows[t];
                if (!row)
                    return false;
                sel = row.start + Math.min(sel - background.rows[r].start, row.count - 1);
                return true;
            }

            // AlwaysOn because the point is to show how much library is left,
            // not only to react to a flick. Dragging it comes with the type.
            ScrollBar.vertical: ScrollBar {
                id: gridScroll
                policy: ScrollBar.AlwaysOn
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: background.shell.palette.fg
                    opacity: gridScroll.pressed ? 0.9 : 0.4
                }
            }

            delegate: Item {
                id: rowItem
                required property var modelData

                width: grid.width
                height: modelData.header ? headerLabel.implicitHeight + 16 : grid.cellHeight

                Text {
                    id: headerLabel
                    visible: rowItem.modelData.header
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    color: background.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    font.bold: true
                    text: rowItem.modelData.label || ""
                }

                Repeater {
                    model: rowItem.modelData.header ? 0 : rowItem.modelData.count

                    Item {
                        id: cell
                        required property int index
                        readonly property int flat: rowItem.modelData.start + index
                        readonly property string path: background.wallpapers[flat]

                        x: index * grid.cellWidth
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 4
                            clip: true
                            color: background.shell.palette.dim
                            border.color: cell.flat === grid.sel ? background.shell.palette.fg : "transparent"
                            border.width: 2

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 480
                                source: "file://" + background.thumbFor(cell.path)
                                // Not yet generated, or magick could not read it.
                                onStatusChanged: if (status === Image.Error)
                                    source = "file://" + cell.path
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    grid.sel = cell.flat;
                                    picker.choose();
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape)
                    picker.close();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    picker.choose();
                else if (event.key === Qt.Key_Left)
                    sel = Math.max(0, sel - 1);
                else if (event.key === Qt.Key_Right)
                    sel = Math.min(background.wallpapers.length - 1, sel + 1);
                else if (event.key === Qt.Key_Down)
                    step(1);
                else if (event.key === Qt.Key_Up) {
                    if (!step(-1))
                        clearButton.forceActiveFocus();
                } else
                    return;
                event.accepted = true;
            }
        }
    }
}
