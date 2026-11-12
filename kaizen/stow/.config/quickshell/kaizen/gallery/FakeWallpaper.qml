import QtQuick

import "../modules/background/WallpaperModel.js" as Model

// The background's members the picker reads, without files: each thumbnail
// is a gradient drawn as an SVG data URL.
QtObject {
    id: fake

    readonly property string root: "/home/you/Pictures/Wallpapers"
    readonly property int columns: 6

    function library(folders) {
        const paths = [];
        for (const folder in folders)
            for (let i = 1; i <= folders[folder]; i++)
                paths.push(root + (folder ? "/" + folder : "") + "/" + String(i).padStart(2, "0") + ".jpg");
        return Model.sorted(paths, root);
    }
    readonly property var several: library({
        "": 4,
        "Ghibli": 15,
        "Ghibli/Arrietty": 8,
        "Landscapes": 13
    })
    readonly property var scenarios: ({
            "Library": {
                wallpapers: several,
                pick: several[6],
                slot: "workspace",
                thumbsRunning: false
            },
            "Thumbnails": {
                wallpapers: several,
                pick: several[6],
                slot: "workspace",
                thumbsRunning: true,
                thumbsDone: 12
            },
            "Backdrop": {
                wallpapers: several,
                pick: "",
                slot: "backdrop",
                thumbsRunning: false
            },
            "One folder": {
                wallpapers: library({
                    "": 5
                }),
                pick: "",
                slot: "workspace",
                thumbsRunning: false
            },
            "Empty": {
                wallpapers: [],
                pick: "",
                slot: "workspace",
                thumbsRunning: false
            }
        })

    property var wallpapers: several
    property string pick: several[6]
    property string slot: "workspace"
    property bool thumbsRunning: false
    property int thumbsDone: 0
    readonly property var layout: Model.layout(wallpapers, root, columns)
    readonly property var rows: layout.rows
    readonly property var rowOfIndex: layout.rowOfIndex

    function currentPick() {
        return pick;
    }

    function setWallpaper(path) {
        pick = path;
    }

    // A sky-to-ground gradient, its hue from the path's place in the list.
    function thumbFor(path) {
        const hue = (wallpapers.indexOf(path) * 0.137) % 1;
        const top = Qt.hsla(hue, 0.45, 0.62, 1).toString();
        const bottom = Qt.hsla((hue + 0.08) % 1, 0.4, 0.28, 1).toString();
        const hill = Qt.hsla((hue + 0.3) % 1, 0.3, 0.2, 1).toString();
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="480" height="270"><defs><linearGradient id="g" x2="0" y2="1"><stop offset="0" stop-color="${top}"/><stop offset="1" stop-color="${bottom}"/></linearGradient></defs><rect width="480" height="270" fill="url(#g)"/><path d="M0 200 Q120 150 240 190 T480 170 V270 H0 Z" fill="${hill}"/></svg>`;
        return "data:image/svg+xml," + encodeURIComponent(svg);
    }
}
