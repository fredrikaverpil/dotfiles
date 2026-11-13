import QtQuick

import "../../../Ui" as Ui
import "../../services/weather/WarningsModel.js" as Warnings
import "../../services/weather/WeatherModel.js" as Model
import "../../../Ui/Time.js" as Time

Column {
    id: root

    required property var shell
    required property var service

    // What the times are read against; set on open.
    property date now: new Date()
    readonly property string updated: service.updatedAt ? Time.stamp(service.updatedAt, now) : ""
    readonly property var outlook: service.outlook
    // SMHI's warnings, then the outlook's risks: [{ level, icon, text }], worst first in each.
    readonly property var alerts: service.warnings.map(warning => ({
                level: warning.level,
                icon: warning.icon,
                text: Warnings.describe(warning, root.now)
            })).concat(outlook ? outlook.risks : [])

    readonly property int cardWidth: 460
    readonly property int cardHeight: implicitHeight + 2 * Ui.Space.cardPadding
    readonly property bool keyNavigation: true

    signal forecastRequested
    signal locationRequested

    width: parent ? parent.width : 0
    spacing: 24

    Ui.PanelHeader {
        shell: root.shell
        title: "Weather"
        value: root.service.ready ? root.service.icon + " " + root.service.temperature : ""
        subtitle: {
            const place = root.service.place === "" ? "Unknown location" : root.service.place;
            if (root.service.ready)
                return place + " · " + root.service.condition;
            return place + " · " + (root.service.failed ? "Forecast unavailable" : "Loading…");
        }
    }

    // Above the details: the values below are older than they look.
    Ui.Section {
        visible: root.service.failed && root.service.ready
        shell: root.shell

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: root.shell.palette.rose
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            text: "Could not update; showing the forecast from " + root.updated
        }
    }

    // The current values and the next 12 hours' extremes, then what in those hours needs
    // attention. The labels name the hours, so the rule heads it bare.
    Ui.Section {
        visible: root.service.ready
        shell: root.shell

        Ui.InfoTable {
            shell: root.shell
            perLine: 2
            entries: [
                {
                    label: "Wind",
                    value: root.service.wind
                },
                {
                    label: "Humidity",
                    value: root.service.humidity
                },
                // MET forecasts gusts only inside its Nordic model; elsewhere the strongest mean
                // wind stands in.
                root.outlook && root.outlook.gust !== null ? {
                    label: "Max gusts, 12 h",
                    value: Math.round(root.outlook.gust) + " m/s"
                } : {
                    label: "Max wind, 12 h",
                    value: root.outlook && root.outlook.wind !== null ? Math.round(root.outlook.wind) + " m/s" : "--"
                },
                {
                    label: "Total rain, 12 h",
                    value: root.outlook && root.outlook.precipitation !== null ? root.outlook.precipitation + " mm" : "--"
                }
            ]
        }

        Column {
            visible: root.alerts.length > 0
            width: parent.width
            topPadding: 8
            spacing: 4

            Repeater {
                model: root.alerts

                delegate: Item {
                    id: alert

                    required property var modelData

                    width: root.width
                    height: alertText.implicitHeight

                    Text {
                        id: alertIcon
                        width: 24
                        color: root.shell.palette[alert.modelData.level]
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: alert.modelData.icon
                    }

                    Text {
                        id: alertText
                        x: alertIcon.width + 8
                        width: parent.width - x
                        wrapMode: Text.WordWrap
                        color: root.shell.palette[alert.modelData.level]
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: alert.modelData.text
                    }
                }
            }
        }

        // 16 under the content (style.md › Panels › Space).
        Row {
            topPadding: 8

            Ui.PanelButton {
                shell: root.shell
                label: "Hourly on yr.no"
                onActivated: root.forecastRequested()
            }
        }
    }

    Ui.Section {
        visible: root.service.days.length > 0
        shell: root.shell
        title: "Forecast"

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.service.days

                delegate: Item {
                    id: day

                    required property var modelData

                    width: root.width
                    height: name.implicitHeight

                    Text {
                        id: glyph
                        width: 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: Model.icon(day.modelData.symbol)
                    }

                    Text {
                        id: name
                        x: glyph.width + 8
                        width: 40
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: day.modelData.name
                    }

                    Text {
                        x: name.x + name.width + 8
                        width: temperatures.x - x - 8
                        elide: Text.ElideRight
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: Model.condition(day.modelData.symbol)
                    }

                    Text {
                        id: temperatures
                        anchors.right: parent.right
                        color: root.shell.palette.fg
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 14
                        text: Model.temperature(day.modelData.maximum) + " / " + Model.temperature(day.modelData.minimum)
                    }
                }
            }
        }
    }

    // CC BY 4.0 requires crediting MET Norway, and SMHI for its warnings,
    // wherever their data is shown.
    Ui.PanelFooter {
        shell: root.shell
        note: (root.updated !== "" ? "Updated " + root.updated + " · " : "") + (root.service.swedish ? "MET Norway and SMHI, CC BY 4.0" : "MET Norway, CC BY 4.0")

        Ui.PanelButton {
            shell: root.shell
            label: "Change location…"
            onActivated: root.locationRequested()
        }
    }
}
