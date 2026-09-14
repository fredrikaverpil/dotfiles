import QtQuick
import QtTest
import "../plugins/services/calendar/CalendarModel.js" as Calendar

TestCase {
  name: "CalendarModel"

  // Local times keep the cases independent of the runner's time zone.
  readonly property var now: new Date(2026, 8, 14, 12, 0)

  function local(day, hour, minute) {
    return Calendar.stamp(new Date(2026, 8, day, hour, minute || 0))
  }

  function test_list_command_spans_three_local_days() {
    const command = Calendar.listCommand(now)
    compare(command.slice(0, 4), ["dcal", "--json", "ipc", "events.list"])
    verify(/^from=2026-09-14T00:00:00[+-]\d\d:\d\d$/.test(command[4]))
    verify(/^to=2026-09-17T00:00:00[+-]\d\d:\d\d$/.test(command[5]))
  }

  function test_events_split_into_days_with_all_day_first() {
    const text = JSON.stringify({ events: [
      { uid: "late", summary: "Late", start: local(14, 17), end: local(14, 17, 30),
        meetingUrl: "https://meet.example/abc", location: "Room" },
      { uid: "week", summary: "Week 38", allDay: true,
        start: "2026-09-14T00:00:00Z", end: "2026-09-16T00:00:00Z" },
      { uid: "night", summary: "", start: local(15, 23), end: local(16, 1),
        meetingUrl: "file:///etc/passwd" },
      { uid: "gone", summary: "Cancelled", status: "cancelled", start: local(14, 9), end: local(14, 10) },
      { uid: "past", summary: "Yesterday", start: local(13, 9), end: local(13, 10) },
    ] })

    const days = Calendar.parse(text, now)

    compare(days.map(day => day.date.getTime()), [
      new Date(2026, 8, 14).getTime(), new Date(2026, 8, 15).getTime(), new Date(2026, 8, 16).getTime(),
    ])
    const week = { uid: "week", start: "2026-09-14T00:00:00Z", summary: "Week 38", location: "",
      meetingUrl: "", allDay: true, at: new Date(2026, 8, 14).getTime(), time: "all day" }
    const night = (time) => ({ uid: "night", start: local(15, 23), summary: "(no title)", location: "",
      meetingUrl: "", allDay: false, at: new Date(2026, 8, 15, 23).getTime(), time: time })
    compare(days.map(day => day.events), [
      [week, { uid: "late", start: local(14, 17), summary: "Late", location: "Room",
        meetingUrl: "https://meet.example/abc", allDay: false,
        at: new Date(2026, 8, 14, 17).getTime(), time: "17:00–17:30" }],
      [week, night("23:00–…")],
      [night("…–01:00")],
    ])
  }

  function test_non_list_replies_are_rejected() {
    verify(Calendar.parse("", now) === null)
    verify(Calendar.parse("{}", now) === null)
    verify(Calendar.parse("Error: dcal daemon not running", now) === null)
    compare(Calendar.parse('{"events":[]}', now).map(day => day.events), [[], [], []])
  }
}
