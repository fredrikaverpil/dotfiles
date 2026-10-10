import QtQuick
import QtTest
import "CalendarModel.js" as Calendar

TestCase {
    name: "CalendarModel"

    // Local times keep the cases independent of the runner's time zone.
    readonly property var now: new Date(2026, 8, 14, 12, 0)

    function local(day, hour, minute) {
        return Calendar.stamp(new Date(2026, 8, day, hour, minute || 0));
    }

    function test_list_command_spans_three_local_days() {
        const command = Calendar.listCommand(now);
        compare(command.slice(0, 4), ["dcal", "--json", "ipc", "events.list"]);
        verify(/^from=2026-09-14T00:00:00[+-]\d\d:\d\d$/.test(command[4]));
        verify(/^to=2026-09-17T00:00:00[+-]\d\d:\d\d$/.test(command[5]));
    }

    readonly property string calendars: JSON.stringify([
        {
            id: "g-family",
            name: "Family",
            accountKind: "google"
        },
        {
            id: "johanna",
            name: "Johannas kalender",
            accountKind: "ical"
        },
        {
            id: "mine",
            name: "My calendar",
            accountKind: "ical"
        },
        {
            id: "other",
            name: "Holidays",
            accountKind: "ical"
        },
    ])

    function test_calendars_map_to_emoji_data() {
        return [
            {
                tag: "regex on name",
                emojiByRegex: {
                    "^Family$": "🏠",
                    "kalender$": "❤️",
                    "^My calendar$": "👤"
                },
                want: {
                    "g-family": "🏠",
                    johanna: "❤️",
                    mine: "👤",
                    other: ""
                }
            },
            {
                tag: "first match in order",
                emojiByRegex: {
                    "^Family$": "🏠",
                    "a": "A"
                },
                want: {
                    "g-family": "🏠",
                    johanna: "A",
                    mine: "A",
                    other: "A"
                }
            },
            {
                tag: "invalid regex skipped",
                emojiByRegex: {
                    "(": "X",
                    "^Holidays$": "🎉"
                },
                want: {
                    "g-family": "",
                    johanna: "",
                    mine: "",
                    other: "🎉"
                }
            },
            {
                tag: "no config",
                emojiByRegex: undefined,
                want: {
                    "g-family": "",
                    johanna: "",
                    mine: "",
                    other: ""
                }
            },
        ];
    }

    function test_calendars_map_to_emoji(data) {
        const got = Calendar.emojis(calendars, data.emojiByRegex);

        compare(got, data.want);
    }

    function test_unreadable_calendars_map_to_no_emoji() {
        compare(Calendar.emojis("Error: dcal daemon not running", {
            ".": "X"
        }), {});
    }

    function test_events_split_into_days_with_all_day_first() {
        const text = JSON.stringify({
            events: [
                {
                    uid: "late",
                    summary: "Late",
                    start: local(14, 17),
                    end: local(14, 17, 30),
                    meetingUrl: "https://meet.example/abc",
                    location: "Room",
                    calendarId: "johanna"
                },
                {
                    uid: "week",
                    summary: "Week 38",
                    allDay: true,
                    calendarId: "g-week",
                    start: "2026-09-14T00:00:00Z",
                    end: "2026-09-16T00:00:00Z"
                },
                {
                    uid: "night",
                    summary: "",
                    start: local(15, 23),
                    end: local(16, 1),
                    meetingUrl: "file:///etc/passwd",
                    calendarId: "unknown"
                },
                {
                    uid: "gone",
                    summary: "Cancelled",
                    status: "cancelled",
                    start: local(14, 9),
                    end: local(14, 10)
                },
                {
                    uid: "past",
                    summary: "Yesterday",
                    start: local(13, 9),
                    end: local(13, 10)
                },
            ]
        });
        const emojis = {
            johanna: "❤️",
            "g-week": "G"
        };

        const days = Calendar.parse(text, now, emojis);

        compare(days.map(day => day.date.getTime()), [new Date(2026, 8, 14).getTime(), new Date(2026, 8, 15).getTime(), new Date(2026, 8, 16).getTime(),]);
        const week = {
            uid: "week",
            start: "2026-09-14T00:00:00Z",
            emoji: "G",
            summary: "Week 38",
            location: "",
            meetingUrl: "",
            allDay: true,
            at: new Date(2026, 8, 14).getTime(),
            until: new Date(2026, 8, 16).getTime(),
            time: "all day"
        };
        const night = time => ({
                    uid: "night",
                    start: local(15, 23),
                    emoji: "",
                    summary: "(no title)",
                    location: "",
                    meetingUrl: "",
                    allDay: false,
                    at: new Date(2026, 8, 15, 23).getTime(),
                    until: new Date(2026, 8, 16, 1).getTime(),
                    time: time
                });
        compare(days.map(day => day.events), [[week,
                {
                    uid: "late",
                    start: local(14, 17),
                    emoji: "❤️",
                    summary: "Late",
                    location: "Room",
                    meetingUrl: "https://meet.example/abc",
                    allDay: false,
                    at: new Date(2026, 8, 14, 17).getTime(),
                    until: new Date(2026, 8, 14, 17, 30).getTime(),
                    time: "17:00–17:30"
                }
            ], [week, night("23:00–…")], [night("…–01:00")],]);
    }

    function test_unreadable_dates_show_once_on_the_first_day() {
        const text = JSON.stringify({
            events: [
                {
                    uid: "timed",
                    summary: "Timed",
                    start: local(14, 9),
                    end: local(14, 10)
                },
                {
                    uid: "garbage",
                    summary: "Garbage",
                    start: "soon",
                    end: local(14, 10),
                    calendarId: "mine"
                },
                {
                    uid: "endless",
                    summary: "Endless",
                    start: local(15, 9)
                },
            ]
        });

        const days = Calendar.parse(text, now, {
            mine: "👤"
        });

        const unreadable = (uid, summary, start, emoji) => ({
                    uid: uid,
                    start: start,
                    emoji: emoji,
                    summary: summary,
                    location: "",
                    meetingUrl: "",
                    allDay: false,
                    at: 0,
                    until: 0,
                    time: "?"
                });
        compare(days.map(day => day.events), [[unreadable("endless", "Endless", local(15, 9), ""), unreadable("garbage", "Garbage", "soon", "👤"),
                {
                    uid: "timed",
                    start: local(14, 9),
                    emoji: "",
                    summary: "Timed",
                    location: "",
                    meetingUrl: "",
                    allDay: false,
                    at: new Date(2026, 8, 14, 9).getTime(),
                    until: new Date(2026, 8, 14, 10).getTime(),
                    time: "09:00–10:00"
                },
            ], [], [],]);
    }

    function test_non_list_replies_are_rejected() {
        verify(Calendar.parse("", now) === null);
        verify(Calendar.parse("{}", now) === null);
        verify(Calendar.parse("Error: dcal daemon not running", now) === null);
        compare(Calendar.parse('{"events":[]}', now).map(day => day.events), [[], [], []]);
    }
}
