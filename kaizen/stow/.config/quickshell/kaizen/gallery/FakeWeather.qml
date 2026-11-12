import QtQuick

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
    readonly property var scenarios: ({
            "Partly cloudy": {
                place: "Göteborg",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated
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
                updatedAt: updated
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
                updatedAt: updated
            },
            "Loading": {
                place: "Göteborg",
                current: null,
                days: [],
                failed: false,
                updatedAt: null
            },
            "Failed": {
                place: "Göteborg",
                current: partly,
                days: forecast,
                failed: true,
                updatedAt: updated
            },
            "Failed, no forecast": {
                place: "Göteborg",
                current: null,
                days: [],
                failed: true,
                updatedAt: null
            },
            "Unknown location": {
                place: "",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated
            },
            "Long place name": {
                place: "Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch",
                current: partly,
                days: forecast,
                failed: false,
                updatedAt: updated
            }
        })

    property string place: "Göteborg"
    property var current: partly
    property var days: forecast
    property bool failed: false
    property var updatedAt: updated
    property bool busy: false

    readonly property bool ready: current !== null
    readonly property string icon: current ? Model.icon(current.symbol) : "󰖐"
    readonly property string condition: current ? Model.condition(current.symbol) : ""
    readonly property string temperature: current ? Model.temperature(current.temperature) : ""
    readonly property string wind: current ? Math.round(current.wind) + " m/s" : ""
    readonly property string humidity: current ? Math.round(current.humidity) + "%" : ""

    function refresh() {
    }
}
