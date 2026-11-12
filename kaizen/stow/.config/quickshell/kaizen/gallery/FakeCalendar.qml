import QtQuick

import "../plugins/calendar/CalendarModel.js" as Model

// The calendar service's members the view reads, without dcal.
QtObject {
    id: fake

    readonly property var now: new Date(2026, 10, 12, 14, 2, 7)
    readonly property var emojis: ({
            "work": "💼",
            "family": "🏠"
        })

    // An events.list entry `day` days from today, from hour to hour.
    function event(uid, day, from, until, summary, extra) {
        const at = (hour, add) => Model.stamp(new Date(2026, 10, 12 + day + (add || 0), Math.floor(hour), (hour % 1) * 60));
        return Object.assign({
            uid: uid,
            calendarId: "work",
            summary: summary,
            start: at(from),
            end: until < from ? at(until, 1) : at(until)
        }, extra || {});
    }
    function allDay(uid, day, summary) {
        const date = new Date(Date.UTC(2026, 10, 12 + day)).toISOString();
        const next = new Date(Date.UTC(2026, 10, 13 + day)).toISOString();
        return {
            uid: uid,
            calendarId: "family",
            summary: summary,
            allDay: true,
            start: date,
            end: next
        };
    }
    function parsed(events) {
        return Model.parse(JSON.stringify({
            events: events
        }), now, emojis);
    }

    readonly property var meet: ({
            meetingUrl: "https://meet.example.com/abc-defg-hij"
        })
    readonly property var busy: [event("standup", 0, 9.5, 9.75, "Standup", meet), event("lunch", 0, 12, 13, "Lunch", {
            calendarId: "family",
            location: "Kafé Hjärtat"
        }), event("review", 0, 14, 15, "Design review: kaizen panels", meet), event("focus", 0, 15.5, 17, "Focus time"), event("dentist", 1, 8, 9, "Dentist", {
            calendarId: "family",
            location: "Folktandvården Odenplan, Stockholm"
        }), event("planning", 1, 10, 11.5, "Quarterly planning with a very long title that has to elide", meet), allDay("birthday", 2, "Johanna's birthday"), event("dinner", 2, 18, 21, "Dinner", {
            calendarId: "family"
        })]
    readonly property var scenarios: ({
            "Busy": {
                failed: false,
                days: parsed(busy)
            },
            "Empty days": {
                failed: false,
                days: parsed([event("late", 0, 23, 0.5, "Late deploy")])
            },
            "Nothing": {
                failed: false,
                days: parsed([])
            },
            "Loading": {
                failed: false,
                days: []
            },
            "dcal not running": {
                failed: true,
                days: []
            }
        })

    property bool failed: false
    property var days: fake.parsed(busy)
    readonly property var requestedAt: now

    function refresh() {
    }
}
