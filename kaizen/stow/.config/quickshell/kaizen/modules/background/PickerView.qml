import QtQuick
import QtQuick.Controls

import "../../Ui" as Ui
import "WallpaperModel.js" as Model

Column {
    id: root

    required property var shell
    // The background.
    required property var service

    readonly property int cardWidth: 1200
    readonly property int cardHeight: 780
    readonly property bool keyNavigation: false
    // The focused wallpaper, which the background previews.
    readonly property string selected: grid.sel >= 0 ? (root.service.wallpapers[grid.sel] || "") : ""
    // Clear holds focus only because the grid was empty.
    property bool clearByDefault: false

    signal closeRequested

    // Focuses the current wallpaper, or Clear without any.
    function reset() {
        grid.pointer = Qt.point(-1, -1);
        grid.sel = Math.max(0, root.service.wallpapers.indexOf(root.service.currentPick()));
        root.clearByDefault = root.service.wallpapers.length === 0;
        if (root.clearByDefault)
            clearButton.forceActiveFocus();
        else
            grid.forceActiveFocus();
    }

    function choose() {
        const path = root.service.wallpapers[grid.sel];
        if (path)
            root.service.setWallpaper(path);
        root.closeRequested();
    }

    function clear() {
        root.service.setWallpaper("");
        root.closeRequested();
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    spacing: 24

    Connections {
        target: root.service
        function onRowsChanged() {
            // A scan that empties the grid leaves no stop with focus; one that fills it takes over from Clear.
            if (root.service.wallpapers.length === 0 ? !clearButton.activeFocus : root.clearByDefault && clearButton.activeFocus)
                root.reset();
            Qt.callLater(grid.reveal);
        }
    }

    Ui.PanelHeader {
        id: header
        shell: root.shell
        title: "Wallpaper"
        subtitle: (root.service.slot === "backdrop" ? "Backdrop" : "Workspace") + " · " + (root.shell.dark ? "Dark" : "Light") + (root.service.thumbsRunning ? " · Thumbnails " + root.service.thumbsDone + "/" + root.service.wallpapers.length : "")
    }

    // A virtualized ListView, not Ui.PanelScroller, which builds every item: a library holds hundreds.
    Item {
        width: parent.width
        height: root.height - header.height - footer.height - 2 * root.spacing

        Ui.Section {
            visible: root.service.wallpapers.length === 0
            shell: root.shell

            Text {
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: "No images in " + root.service.shownWallpaperDir
            }
        }

        ListView {
            id: grid
            visible: root.service.wallpapers.length > 0
            anchors.fill: parent
            clip: true
            focus: true
            activeFocusOnTab: true
            keyNavigationEnabled: false
            boundsBehavior: Flickable.StopAtBounds
            // Index into service.wallpapers; the view's own currentIndex
            // counts rows, headers included.
            property int sel: 0
            // Cells scrolled under a resting pointer report hover too; act on real motion only.
            property point pointer: Qt.point(-1, -1)
            readonly property int gap: 8
            readonly property real cellWidth: (width - (root.service.columns - 1) * gap) / root.service.columns
            readonly property real cellHeight: cellWidth * 9 / 16
            model: root.service.rows
            onSelChanged: reveal()
            ScrollBar.vertical: scrollBar

            function moved(point) {
                if (point.x === pointer.x && point.y === pointer.y)
                    return false;
                const first = pointer.x < 0;
                pointer = point;
                return !first;
            }

            // Keeps the selected row in view, and its folder's label too when it is the folder's first row.
            function reveal() {
                for (const r of Model.reveal(root.service.rows, root.service.rowOfIndex, sel))
                    positionViewAtIndex(r, ListView.Contain);
            }

            // Moves one image row up or down, skipping headers.
            function step(dir) {
                const next = Model.step(root.service.rows, root.service.rowOfIndex, sel, dir);
                if (next < 0)
                    return false;
                sel = next;
                return true;
            }

            // A folder's rule and label, 24 under the previous folder's last row (its 8 below, plus 16), then a row
            // of thumbnails 8 under it, each row 8 above the next.
            delegate: Item {
                id: rowItem
                required property var modelData
                required property int index

                width: grid.width
                height: modelData.header ? section.y + section.height + grid.gap : grid.cellHeight + grid.gap

                Ui.Section {
                    id: section
                    visible: rowItem.modelData.header
                    y: rowItem.index > 0 ? 16 : 0
                    width: grid.width
                    shell: root.shell
                    title: rowItem.modelData.label || ""
                }

                Repeater {
                    model: rowItem.modelData.header ? 0 : rowItem.modelData.count

                    // Focus and hover take a 2 px `fg` outline: a `sel` fill would not show over the image.
                    Rectangle {
                        id: cell
                        required property int index
                        readonly property int flat: rowItem.modelData.start + index
                        readonly property string path: root.service.wallpapers[flat]

                        x: index * (grid.cellWidth + grid.gap)
                        width: grid.cellWidth
                        height: grid.cellHeight
                        radius: 4
                        clip: true
                        color: root.shell.palette.dim
                        border.color: cell.flat === grid.sel && grid.activeFocus ? root.shell.palette.fg : "transparent"
                        border.width: 2

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 480
                            source: root.service.thumbFor(cell.path)
                            // Not yet generated, or magick could not read it.
                            onStatusChanged: if (status === Image.Error)
                                source = "file://" + cell.path
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPositionChanged: function (mouse) {
                                if (!grid.moved(mapToItem(null, mouse.x, mouse.y)))
                                    return;
                                grid.sel = cell.flat;
                                grid.forceActiveFocus();
                            }
                            onClicked: {
                                grid.sel = cell.flat;
                                root.choose();
                            }
                        }
                    }
                }
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape)
                    root.closeRequested();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                    root.choose();
                else if (event.key === Qt.Key_Left || event.text === "h")
                    sel = Math.max(0, sel - 1);
                else if (event.key === Qt.Key_Right || event.text === "l")
                    sel = Math.min(root.service.wallpapers.length - 1, sel + 1);
                else if (event.key === Qt.Key_Down || event.text === "j") {
                    if (!step(1))
                        clearButton.forceActiveFocus(Qt.TabFocusReason);
                } else if (event.key === Qt.Key_Up || event.text === "k")
                    step(-1);
                else
                    return;
                event.accepted = true;
            }
        }

        Ui.PanelScrollBar {
            id: scrollBar
            x: grid.width + 10
            height: grid.height
            shell: root.shell
        }
    }

    Ui.PanelFooter {
        id: footer
        shell: root.shell

        Ui.PanelButton {
            id: clearButton
            shell: root.shell
            label: "Clear wallpaper"
            onActivated: root.clear()

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape)
                    root.closeRequested();
                else if (event.key === Qt.Key_Up || event.text === "k")
                    grid.forceActiveFocus(Qt.TabFocusReason);
                else
                    return;
                event.accepted = true;
            }
        }
    }
}
