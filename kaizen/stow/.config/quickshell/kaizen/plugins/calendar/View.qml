import QtQuick

import qs.Ui as Ui
import "CalendarModel.js" as Model

Column {
    id: root

    required property var shell
    // The calendar service, or the gallery's stand-in.
    required property var service

    // What past and under way are read against: the fetch, as the events.
    readonly property date now: service.requestedAt
    readonly property bool loading: !service.failed && service.days.length === 0

    readonly property int cardWidth: 600
    readonly property int cardPadding: 16
    readonly property int cardHeight: implicitHeight + 2 * cardPadding
    readonly property bool keyNavigation: true

    signal openRequested(var event)
    signal joinRequested(var event)
    signal appRequested

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Calendar"
        subtitle: {
            if (root.service.failed)
                return "";
            if (root.loading)
                return "Loading…";
            return Model.nextLabel(root.service.days, root.now);
        }
    }

    Ui.Section {
        visible: root.service.failed
        shell: root.shell

        Text {
            width: root.width
            wrapMode: Text.WordWrap
            color: root.shell.palette.rose
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "dcal is not running"
        }
    }

    Ui.PanelScroller {
        visible: root.service.days.length > 0
        shell: root.shell
        spacing: 24

        Repeater {
            model: root.service.days

            delegate: DaySection {}
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            shell: root.shell
            label: "Open calendar…"
            onActivated: root.appRequested()
        }
    }

    // A day: "Today" and "Tomorrow" name it, their date at the rule's right; later days by their date.
    component DaySection: Ui.Section {
        id: day

        required property var modelData
        required property int index
        readonly property string date: Qt.formatDateTime(modelData.date, "dddd d MMMM")

        shell: root.shell
        title: index < 2 ? ["Today", "Tomorrow"][index] : date
        value: index < 2 ? date : ""

        Column {
            width: root.width
            spacing: 4

            Repeater {
                model: day.modelData.events

                delegate: EventRow {}
            }

            Text {
                visible: day.modelData.events.length === 0
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: "No events"
            }
        }
    }

    // The widest time a row shows, so the summaries start together.
    TextMetrics {
        id: timeMetrics
        font.family: Ui.Fonts.mono
        font.pixelSize: 14
        text: "00:00–00:00"
    }

    // An event: Enter, Space or a click opens it in dcal; Join, its own stop, opens the meeting.
    component EventRow: Item {
        id: row

        required property var modelData
        readonly property bool past: modelData.until > 0 && modelData.until <= root.now.getTime()
        readonly property color textColor: past ? root.shell.palette.off : root.shell.palette.fg

        width: root.width
        implicitHeight: 28
        activeFocusOnTab: true

        Keys.onReturnPressed: root.openRequested(row.modelData)
        Keys.onEnterPressed: root.openRequested(row.modelData)
        Keys.onSpacePressed: root.openRequested(row.modelData)

        // The fill reaches into the card's padding, so the text aligns with the rule.
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            radius: 4
            color: row.activeFocus || mouse.containsMouse ? root.shell.palette.sel : "transparent"
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            hoverEnabled: true
            onClicked: root.openRequested(row.modelData)
        }

        Text {
            id: emoji
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            opacity: row.past ? 0.5 : 1
            text: row.modelData.emoji
        }

        Text {
            id: time
            anchors.left: emoji.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: timeMetrics.advanceWidth
            color: Model.underway(row.modelData, root.now) ? root.shell.palette.fg : root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: row.modelData.time
        }

        // The summary keeps its room; the location takes what is left.
        Text {
            id: summary
            anchors.left: time.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, (join.visible ? join.x - 16 : row.width) - x)
            elide: Text.ElideRight
            color: row.textColor
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            textFormat: Text.PlainText
            text: row.modelData.summary
        }

        Text {
            anchors.left: summary.right
            anchors.leftMargin: 16
            anchors.right: join.visible ? join.left : parent.right
            anchors.rightMargin: join.visible ? 16 : 0
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            textFormat: Text.PlainText
            text: row.modelData.location
        }

        Ui.PanelButton {
            id: join
            visible: row.modelData.meetingUrl !== "" && !row.past
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            shell: root.shell
            label: "Join"
            onActivated: root.joinRequested(row.modelData)
        }
    }
}
