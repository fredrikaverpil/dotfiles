import QtQuick

import "../../../Ui" as Ui
import "../../services/weather/WeatherModel.js" as Model

Column {
    id: root

    required property var shell
    required property var service

    readonly property string updated: service.updatedAt ? Qt.formatDateTime(service.updatedAt, "HH:mm") : ""

    readonly property int cardWidth: 400
    readonly property int cardPadding: 16
    readonly property int cardHeight: implicitHeight + 2 * cardPadding
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
                {
                    label: "Updated",
                    value: root.updated
                }
            ]
        }

        Ui.PanelButton {
            shell: root.shell
            label: "Today on yr.no"
            onActivated: root.forecastRequested()
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

    // CC BY 4.0 requires crediting MET Norway wherever their data is shown.
    Ui.PanelFooter {
        shell: root.shell
        note: "MET Norway, CC BY 4.0"

        Ui.PanelButton {
            shell: root.shell
            label: "Change location…"
            onActivated: root.locationRequested()
        }
    }
}
