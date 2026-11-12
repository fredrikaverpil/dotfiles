import QtQuick
import QtQuick.Controls

import "../../Ui" as Ui

Column {
    id: root

    required property var shell
    // The background, or the gallery's stand-in.
    required property var service

    readonly property int cardWidth: 1200
    readonly property int cardHeight: 780
    readonly property bool keyNavigation: false
    // The focused wallpaper, which the background previews.
    readonly property string selected: grid.sel >= 0 ? (root.service.wallpapers[grid.sel] || "") : ""

    signal closeRequested

    // Focuses the current wallpaper.
    function reset() {
        grid.pointer = Qt.point(-1, -1);
        grid.sel = Math.max(0, root.service.wallpapers.indexOf(root.service.currentPick()));
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
    spacing: 8

    Connections {
        target: root.service
        function onRowsChanged() {
            Qt.callLater(grid.reveal);
        }
    }

    Item {
        width: parent.width
        height: Math.max(title.height, clearButton.height)

        Text {
            id: title
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 15
            text: "Wallpaper (" + root.service.slot + ") · " + (root.shell.dark ? "dark" : "light") + (root.service.thumbsRunning ? " · thumbnails " + root.service.thumbsDone + "/" + root.service.wallpapers.length : "")
        }

        Rectangle {
            id: clearButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: clearLabel.width + 20
            height: clearLabel.height + 10
            radius: 4
            activeFocusOnTab: true
            color: activeFocus ? root.shell.palette.dim : "transparent"
            border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1

            Text {
                id: clearLabel
                anchors.centerIn: parent
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: "󰅖 Clear"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.clear()
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape)
                    root.closeRequested();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                    root.clear();
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
        // Index into service.wallpapers; the view's own currentIndex
        // counts rows, headers included.
        property int sel: 0
        // Cells scrolled under a resting pointer report hover too; act on real motion only.
        property point pointer: Qt.point(-1, -1)
        readonly property real cellWidth: (width - 16) / root.service.columns
        readonly property real cellHeight: cellWidth * 9 / 16
        model: root.service.rows
        onSelChanged: reveal()

        function moved(point) {
            if (point.x === pointer.x && point.y === pointer.y)
                return false;
            const first = pointer.x < 0;
            pointer = point;
            return !first;
        }

        // Keeps a section's header in view when its first row is selected.
        function reveal() {
            let r = root.service.rowOfIndex[sel];
            if (r === undefined)
                return;
            if (root.service.rows[r - 1] && root.service.rows[r - 1].header)
                r--;
            positionViewAtIndex(r, ListView.Contain);
        }

        // Moves one image row up or down, skipping headers.
        function step(dir) {
            const r = root.service.rowOfIndex[sel];
            if (r === undefined)
                return false;
            let t = r + dir;
            while (root.service.rows[t] && root.service.rows[t].header)
                t += dir;
            const row = root.service.rows[t];
            if (!row)
                return false;
            sel = row.start + Math.min(sel - root.service.rows[r].start, row.count - 1);
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
                color: root.shell.palette.fg
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
                color: root.shell.palette.fg
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
                    readonly property string path: root.service.wallpapers[flat]

                    x: index * grid.cellWidth
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 4
                        clip: true
                        color: root.shell.palette.dim
                        border.color: cell.flat === grid.sel ? root.shell.palette.fg : "transparent"
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
                                if (grid.moved(mapToItem(null, mouse.x, mouse.y)))
                                    grid.sel = cell.flat;
                            }
                            onClicked: {
                                grid.sel = cell.flat;
                                root.choose();
                            }
                        }
                    }
                }
            }
        }

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape)
                root.closeRequested();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.choose();
            else if (event.key === Qt.Key_Left)
                sel = Math.max(0, sel - 1);
            else if (event.key === Qt.Key_Right)
                sel = Math.min(root.service.wallpapers.length - 1, sel + 1);
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
