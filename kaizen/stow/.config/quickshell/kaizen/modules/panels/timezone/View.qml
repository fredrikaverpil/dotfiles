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
    readonly property var warnings: [
        {
            text: mismatch === "" ? "" : "Not applied: timedated reports " + info.zone + " but /etc/localtime is " + mismatch + ".",
            role: "rose"
        },
        {
            text: !stale ? "" : "The bar clock is still on the zone this shell started with. Apply with: kaizen reload --restart",
            role: "wood"
        },
        {
            text: root.service.lastError,
            role: "rose"
        },
    ].filter(warning => warning.text !== "")

    readonly property string offsetText: {
        const seconds = Model.offsetSeconds(info.offset);
        if (seconds === null)
            return "";
        const abbreviation = Model.abbreviationLabel(info.abbreviation, info.offset);
        return (abbreviation === "" ? "" : abbreviation + " ") + Model.offsetLabel(seconds);
    }

    signal zoneRequested

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Time"
        value: root.info.time === "" ? "--:--:--" : root.info.time
        subtitle: {
            if (root.info.zone === "")
                return "Zone unknown";
            return root.offsetText === "" ? root.info.zone : root.info.zone + " · " + root.offsetText;
        }
    }

    // Above the details: a change that did not land is the reason to have opened this.
    Ui.Section {
        visible: root.warnings.length > 0
        shell: root.shell

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.warnings

                delegate: Text {
                    required property var modelData

                    width: root.width
                    wrapMode: Text.WordWrap
                    color: root.shell.palette[modelData.role]
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
                    text: modelData.text
                }
            }
        }
    }

    Ui.Section {
        shell: root.shell

        Ui.InfoTable {
            shell: root.shell
            entries: [
                {
                    label: "Date",
                    value: root.info.weekday + " " + root.info.date
                },
                {
                    label: "UTC",
                    value: root.info.utcTime + " " + root.info.utcDate
                },
                {
                    label: "DST",
                    value: Model.dstLabel(root.info.dst)
                },
                {
                    label: "Next",
                    value: Model.nextLabel(root.info.dst)
                },
                {
                    label: "NTP",
                    value: root.info.synchronized ? "Synchronised" : "Not synchronised",
                    role: root.info.synchronized ? "fg" : "wood"
                }
            ]
        }
    }

    Ui.PanelFooter {
        shell: root.shell

        Ui.PanelButton {
            shell: root.shell
            label: "Change timezone…"
            onActivated: root.zoneRequested()
        }
    }
}
