import QtQuick

import "../../../Ui" as Ui
import "../../services/timezone/TimezoneModel.js" as Model

Column {
    id: root

    required property var shell
    required property var service

    readonly property var info: service.info

    // The zone in force when it is not the one timedated reports, else "".
    readonly property string mismatch: Model.zoneMismatch(info.zone, info.link)
    // "tt" is what the bar's own clock resolves to, in date(1)'s %z form.
    readonly property bool stale: Model.staleClock(info.offset, Qt.formatDateTime(new Date(), "tt"))
    readonly property var warnings: [mismatch === "" ? "" : "󰀦 Not applied: timedated reports " + info.zone + " but /etc/localtime is " + mismatch + ".", !stale ? "" : "󰀦 The bar clock is still on the zone this shell started with. " + "Apply with: systemctl --user restart quickshell", root.service.lastError,].filter(text => text !== "")

    readonly property int cardWidth: 460
    // Each warning wraps to about two lines; the card grows rather than clipping
    // the rows or swallowing the reason a change did not land.
    readonly property int cardHeight: 356 + warnings.length * 40
    readonly property bool keyNavigation: true

    readonly property var rows: [
        {
            label: "Zone",
            value: info.zone === "" ? "unknown" : info.zone
        },
        {
            label: "Date",
            value: info.weekday + " " + info.date
        },
        {
            label: "Offset",
            value: root.offsetText
        },
        {
            label: "UTC",
            value: info.utcTime + "   " + info.utcDate
        },
        {
            label: "DST",
            value: Model.dstLabel(info.dst)
        },
        {
            label: "Next",
            value: Model.nextLabel(info.dst)
        },
        {
            label: "NTP",
            value: info.synchronized ? "Synchronised" : "Not synchronised"
        },
    ]

    readonly property string offsetText: {
        const seconds = Model.offsetSeconds(info.offset);
        if (seconds === null)
            return "unknown";
        const abbreviation = Model.abbreviationLabel(info.abbreviation, info.offset);
        return (abbreviation === "" ? "" : abbreviation + "   ") + Model.offsetLabel(seconds);
    }

    signal zoneRequested

    width: parent ? parent.width : 0
    spacing: 8

    Text {
        width: parent.width
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 18
        text: "Clock"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Text {
        width: parent.width
        color: root.shell.palette.fg
        font.family: Ui.Fonts.mono
        font.pixelSize: 40
        text: root.info.time === "" ? "--:--:--" : root.info.time
    }

    // Above the rows: a change that did not land is the reason to have opened this.
    Repeater {
        model: root.warnings

        delegate: Text {
            required property string modelData

            width: root.cardWidth - 24
            wrapMode: Text.WordWrap
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
            text: modelData
        }
    }

    Repeater {
        model: root.rows

        delegate: Row {
            id: fieldRow

            required property var modelData

            width: root.width
            height: 20
            spacing: 10

            Text {
                width: 64
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: fieldRow.modelData.label
            }

            Text {
                width: parent.width - 74
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: fieldRow.modelData.value
            }
        }
    }

    Item {
        width: parent.width
        height: 4
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: 4
        color: activeFocus ? root.shell.palette.sel : "transparent"
        border.color: activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: root.zoneRequested()
        Keys.onEnterPressed: root.zoneRequested()
        Keys.onSpacePressed: root.zoneRequested()

        Text {
            anchors.centerIn: parent
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: "󰅐 Change timezone"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.zoneRequested()
        }
    }
}
