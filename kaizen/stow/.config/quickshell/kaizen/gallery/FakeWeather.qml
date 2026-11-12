import QtQuick

import "../modules/services/weather/WarningsModel.js" as Warnings
import "../modules/services/weather/WeatherModel.js" as Model

// The weather service's members the view reads, without fetching from MET.
QtObject {
    id: fake

    readonly property var updated: new Date(2026, 10, 12, 14, 2, 33)
    readonly property var partly: ({
            symbol: "partlycloudy_day",
            temperature: 12.3,
            wind: 4.2,
            humidity: 81
        })
    readonly property var forecast: [
        {
            date: "2026-11-13",
            name: "Fri",
            symbol: "partlycloudy_day",
            maximum: 12.4,
            minimum: 4.1
        },
        {
            date: "2026-11-14",
            name: "Sat",
            symbol: "rain",
            maximum: 9.2,
            minimum: 3.0
        },
        {
            date: "2026-11-15",
            name: "Sun",
            symbol: "clearsky_day",
            maximum: 11.0,
            minimum: -1.6
        }
    ]
    readonly property var calm: ({
            hours: 12,
            precipitation: 0.4,
            wind: 5.1,
            gust: 9.8,
            thunder: 2,
            thunderSymbol: false,
            risks: [],
            level: ""
        })
    readonly property var stormy: ({
            hours: 12,
            precipitation: 14.2,
            wind: 18.4,
            gust: 27.1,
            thunder: 41,
            thunderSymbol: true,
            risks: [
                {
                    level: "rose",
                    icon: Model.RISK_GLYPHS.wind,
                    text: "Gale, gusts up to 27 m/s"
                },
                {
                    level: "wood",
                    icon: Model.RISK_GLYPHS.thunder,
                    text: "Risk of thunder"
                }
            ],
            level: "rose"
        })
    function smhi(level, severity, event, startHour, endHour) {
        return {
            level: level,
            icon: Warnings.eventGlyph(event.toUpperCase()),
            severity: severity,
            event: event,
            area: "Västra Götaland",
            start: new Date(2026, 10, 12, startHour, 0).getTime(),
            end: endHour === null ? null : new Date(2026, 10, 12, endHour, 0).getTime()
        };
    }
    readonly property var scenarios: ({
            "Partly cloudy": {
                place: "Göteborg",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Rain": {
                place: "Göteborg",
                current: {
                    symbol: "heavyrainshowersandthunder_day",
                    temperature: 8.6,
                    wind: 11.8,
                    humidity: 96
                },
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Night": {
                place: "Göteborg",
                current: {
                    symbol: "clearsky_night",
                    temperature: -4.4,
                    wind: 0.6,
                    humidity: 70
                },
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Loading": {
                place: "Göteborg",
                current: null,
                days: [],
                failed: false,
                updatedAt: null,
                outlook: null,
                warnings: [],
                swedish: true
            },
            "Failed": {
                place: "Göteborg",
                current: partly,
                days: forecast,
                failed: true,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Failed, no forecast": {
                place: "Göteborg",
                current: null,
                days: [],
                failed: true,
                updatedAt: null,
                outlook: null,
                warnings: [],
                swedish: true
            },
            "Unknown location": {
                place: "",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Long place name": {
                place: "Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [],
                swedish: true
            },
            "Thunder": {
                place: "Göteborg",
                current: {
                    symbol: "heavyrainshowersandthunder_day",
                    temperature: 8.6,
                    wind: 7.8,
                    humidity: 96
                },
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: {
                    hours: 12,
                    precipitation: 9.8,
                    wind: 7.8,
                    gust: 13.6,
                    thunder: 43,
                    thunderSymbol: true,
                    risks: [
                        {
                            level: "wood",
                            icon: Model.RISK_GLYPHS.thunder,
                            text: "Risk of thunder"
                        }
                    ],
                    level: "wood"
                },
                warnings: [],
                swedish: true
            },
            "Gale": {
                place: "Göteborg",
                current: {
                    symbol: "rain",
                    temperature: 7.1,
                    wind: 17.9,
                    humidity: 93
                },
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: stormy,
                warnings: [],
                swedish: true
            },
            "SMHI yellow": {
                place: "Göteborg",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: calm,
                warnings: [smhi("wood", "Yellow", "Wind", 10, 23)],
                swedish: true
            },
            "SMHI red": {
                place: "Göteborg",
                current: {
                    symbol: "rain",
                    temperature: 7.1,
                    wind: 17.9,
                    humidity: 93
                },
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: stormy,
                warnings: [smhi("rose", "Red", "Wind", 18, null), smhi("wood", "Yellow", "Rain", 10, 23)],
                swedish: true
            },
            "Abroad": {
                place: "Madrid",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated,
                outlook: {
                    hours: 12,
                    precipitation: 0,
                    wind: 7.5,
                    gust: null,
                    thunder: null,
                    thunderSymbol: false,
                    risks: [],
                    level: ""
                },
                warnings: [],
                swedish: false
            }
        })

    property string place: "Göteborg"
    property var current: partly
    property var days: forecast
    property bool failed: false
    property var updatedAt: updated
    property var outlook: calm
    property var warnings: []
    property bool swedish: true

    readonly property bool ready: current !== null
    readonly property var alertGlyphs: Warnings.glyphs(warnings.concat(outlook ? outlook.risks : []))
    readonly property string icon: current ? Model.icon(current.symbol) : "󰖐"
    readonly property string condition: current ? Model.condition(current.symbol) : ""
    readonly property string temperature: current ? Model.temperature(current.temperature) : ""
    readonly property string wind: current ? Math.round(current.wind) + " m/s" : ""
    readonly property string humidity: current ? Math.round(current.humidity) + "%" : ""
}
