import QtQuick
import QtQuick.Window

import qs.Ui as Ui

Column {
    id: root

    required property var shell
    // The calendar service, or the gallery's stand-in.
    required property var service

    readonly property int cardWidth: 520
    readonly property int cardHeight: 460
    readonly property bool keyNavigation: true

    signal openRequested(var event)
    signal joinRequested(var event)

    readonly property var focusedItem: scroller.Window.activeFocusItem
    // Map to content coordinates: Flickable coordinates are relative to its viewport.
    onFocusedItemChanged: {
        const item = focusedItem;
        if (!item)
            return;
        const top = item.mapToItem(body, 0, 0).y;
        if (!isFinite(top))
            return;
        if (top < scroller.contentY)
            scroller.contentY = Math.max(0, top);
        else if (top + item.height > scroller.contentY + scroller.height)
            scroller.contentY = top + item.height - scroller.height;
    }

    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    spacing: 8

    Text {
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 18
        text: "Calendar"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Text {
        visible: root.service.failed
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13
        text: "dcal is not running"
    }

    Flickable {
        id: scroller
        width: parent.width
        height: parent.height - y
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: scroller.width
            spacing: 10

            Repeater {
                model: root.service.days

                delegate: DaySection {}
            }
        }
    }

    component DaySection: Column {
        id: day

        required property var modelData
        required property int index

        width: parent.width
        spacing: 2

        Text {
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            font.bold: true
            text: (day.index < 2 ? ["Today", "Tomorrow"][day.index] + " · " : "") + Qt.formatDateTime(day.modelData.date, "dddd d MMMM")
        }

        Repeater {
            model: day.modelData.events

            delegate: EventRow {}
        }

        Text {
            visible: day.modelData.events.length === 0
            leftPadding: 8
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: "No events"
        }
    }

    component EventRow: Rectangle {
        id: row

        required property var modelData
        // Ended before the fetch; dimmed like the time column.
        readonly property bool past: modelData.until > 0 && modelData.until <= root.service.requestedAt.getTime()

        width: parent.width
        height: 30
        radius: 4
        color: activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
        activeFocusOnTab: true

        Keys.onReturnPressed: root.openRequested(row.modelData)
        Keys.onEnterPressed: root.openRequested(row.modelData)
        Keys.onSpacePressed: root.openRequested(row.modelData)

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.openRequested(row.modelData)
        }

        Text {
            id: emoji
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            horizontalAlignment: Text.AlignHCenter
            color: row.past ? root.shell.palette.off : root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: row.modelData.emoji
        }

        Text {
            id: time
            anchors.left: emoji.right
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 104
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: row.modelData.time
        }

        Text {
            anchors.left: time.right
            anchors.right: joinButton.visible ? joinButton.left : parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: row.past ? root.shell.palette.off : root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: row.modelData.summary + (row.modelData.location ? "  · " + row.modelData.location : "")
        }

        Rectangle {
            id: joinButton
            visible: row.modelData.meetingUrl !== ""
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 72
            height: 22
            radius: 4
            color: activeFocus || joinMouse.containsMouse ? root.shell.palette.sel : "transparent"
            border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1
            activeFocusOnTab: visible

            Keys.onReturnPressed: root.joinRequested(row.modelData)
            Keys.onEnterPressed: root.joinRequested(row.modelData)
            Keys.onSpacePressed: root.joinRequested(row.modelData)

            Text {
                anchors.centerIn: parent
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: "󰍫 Join"
            }

            MouseArea {
                id: joinMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.joinRequested(row.modelData)
            }
        }
    }
}
