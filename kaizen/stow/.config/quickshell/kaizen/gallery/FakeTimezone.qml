import QtQuick

import "../modules/services/timezone/TimezoneModel.js" as Model

// The timezone service's members the view reads, without timedatectl or zdump.
QtObject {
    id: fake

    // The gallery's own offset, so only "Changed, not restarted" reads as a stale bar clock.
    readonly property string localOffset: Qt.formatDateTime(new Date(), "tt")
    readonly property var stockholm: ({
            zone: "Europe/Stockholm",
            link: "/etc/zoneinfo/Europe/Stockholm",
            synchronized: true,
            time: "14:32:07",
            date: "2026-11-11",
            weekday: "Wed",
            offset: localOffset,
            abbreviation: "CET",
            utcTime: "13:32:07",
            utcDate: "2026-11-11",
            dst: {
                observed: true,
                inEffect: false,
                next: {
                    local: "Sun 28 Mar 2027, 03:00",
                    abbreviation: "CEST",
                    dst: true,
                    offset: 7200
                }
            }
        })
    readonly property var scenarios: ({
            "Stockholm": {
                info: stockholm,
                lastError: ""
            },
            "Not synchronised": {
                info: Object.assign({}, stockholm, {
                    synchronized: false
                }),
                lastError: ""
            },
            "Changed, not restarted": {
                info: {
                    zone: "Asia/Kolkata",
                    link: "/etc/zoneinfo/Asia/Kolkata",
                    synchronized: true,
                    time: "19:02:07",
                    date: "2026-11-11",
                    weekday: "Wed",
                    offset: "+0530",
                    abbreviation: "IST",
                    utcTime: "13:32:07",
                    utcDate: "2026-11-11",
                    dst: {
                        observed: false,
                        inEffect: false,
                        next: null
                    }
                },
                lastError: ""
            },
            "Not applied": {
                info: Object.assign({}, stockholm, {
                    zone: "Asia/Tokyo"
                }),
                lastError: ""
            },
            "Failed": {
                info: stockholm,
                lastError: "Failed to set time zone: Access denied"
            },
            "Unknown": {
                info: Model.parse(""),
                lastError: ""
            }
        })

    property var info: stockholm
    property string lastError: ""
    property bool polling: false
    readonly property bool fresh: true
    readonly property string zone: info.zone

    function refresh() {
    }

    function setZone(name) {
        return String(name || "") !== "";
    }

    function resetZone() {
        return true;
    }
}
