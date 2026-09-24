import QtQuick
import QtTest
import "../plugins/notifications/NotificationLogic.js" as Notification

TestCase {
  name: "NotificationLogic"

  function test_notification_snapshots_normalize_optional_fields_and_preserve_supplied_time() {
    compare(Notification.asString(null), "")
    compare(Notification.asString(4), "4")
    compare(Notification.snapshotOf({ appName: "Mail", urgency: 2 }, 123), {
      app: "Mail", appIcon: "", summary: "", body: "", image: "", urgency: 2, timestamp: 123,
    })
  }

  function test_notification_calendar_reminders_name_their_source() {
    compare(Notification.calendarReminder({ appName: "Slack", summary: "[einride] from Google Calendar" }), "slack")
    compare(Notification.calendarReminder({ appName: "Chromium", body: "calendar.google.com\n\n09:00 – 09:30" }), "chromium")
    compare(Notification.calendarReminder({ appName: "Slack", summary: "[einride] from Jira" }), "")
    compare(Notification.calendarReminder({}), "")
  }

  function test_notification_urgency_raises_calendar_reminders_to_critical() {
    compare(Notification.urgencyOf({ appName: "Slack", summary: "[einride] from Google Calendar", urgency: 1 }), 2)
    compare(Notification.urgencyOf({ appName: "Slack", summary: "[einride] from Jira", urgency: 1 }), 1)
    compare(Notification.urgencyOf({ appName: "Chromium", summary: "Standup", body: "calendar.google.com\n10:00 – 10:15", urgency: 1 }), 2)
    compare(Notification.urgencyOf({ appName: "Chromium", summary: "Mail", body: "mail.google.com\ncalendar.google.com", urgency: 1 }), 1)
    compare(Notification.urgencyOf({ appName: "Mail", summary: "from Google Calendar", urgency: 0 }), 0)
    compare(Notification.durationFor({ appName: "Slack", summary: "[x] from Google Calendar", urgency: 1, expireTimeout: 1 }, 0, 2), 0)
  }

  function test_notification_icon_sources_preserve_schemes_and_normalize_paths() {
    compare(Notification.iconSource("/tmp/icon.png"), "file:///tmp/icon.png")
    compare(Notification.iconSource("file:///tmp/icon.png"), "file:///tmp/icon.png")
    compare(Notification.iconSource("image://icon/mail"), "image://icon/mail")
    compare(Notification.iconSource("mail"), "mail")
    compare(Notification.iconSource(null), "")
  }

  function test_notification_emojify_replaces_known_shortcodes_only() {
    const codes = { hammer_and_wrench: "🛠️", memo: "📝", "+1": "👍", "skin-tone-2": "🏻" }
    compare(Notification.emojify("Up next: :hammer_and_wrench::memo: Sprint :+1::skin-tone-2: :custom: 10:30:00", codes),
      "Up next: 🛠️📝 Sprint 👍🏻 :custom: 10:30:00")
  }

  function test_notification_duration_honors_urgency_residency_and_bounds() {
    const low = 0
    const critical = 2
    compare(Notification.durationFor({ urgency: critical, expireTimeout: 1 }, low, critical), 0)
    compare(Notification.durationFor({ urgency: 1, resident: true }, low, critical), 0)
    compare(Notification.durationFor({ urgency: low, expireTimeout: 1 }, low, critical), 5000)
    compare(Notification.durationFor({ urgency: 1, expireTimeout: 1 }, low, critical), 8000)
    compare(Notification.durationFor({ urgency: 1, expireTimeout: 99999 }, low, critical), 30000)
    compare(Notification.durationFor({ urgency: 1, expireTimeout: "invalid" }, low, critical), 8000)
    compare(Notification.durationFor({ urgency: 1, expireTimeout: 0 }, low, critical), 0)
    compare(Notification.durationFor({ urgency: 1, expireTimeout: -1 }, low, critical), 8000)
  }

  function test_notification_buttons_skip_the_default_action() {
    const open = { identifier: "default", text: "Open" }
    const reply = { identifier: "reply", text: "Reply" }
    const mute = { identifier: "mute", text: "Mute" }
    compare(Notification.buttons([open, reply, mute]), [reply, mute])
    compare(Notification.buttons([open]), [])
    compare(Notification.buttons(null), [])
  }
}
