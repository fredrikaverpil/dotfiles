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

  function test_notification_urgency_raises_notifications_matching_every_field_of_a_critical_rule() {
    const rules = Notification.compileRules([
      { match: { app: "^Slack$", summary: " in #?alerts$" }, critical: true },
      { match: { app: "^Slack$", summary: " in #general$" } },
      { match: { body: "[" }, critical: true },
      { match: {}, critical: true },
      { critical: true },
      { match: { sumary: "x" }, critical: true },
    ])

    compare(Notification.urgencyOf({ appName: "Slack", summary: "[x] in #alerts", urgency: 1 }, rules), 2)
    compare(Notification.urgencyOf({ appName: "Slack", summary: "New message in alerts", urgency: 1 }, rules), 2)
    compare(Notification.urgencyOf({ appName: "Slack", summary: "[x] in #general", urgency: 1 }, rules), 1)
    compare(Notification.urgencyOf({ appName: "Chromium", summary: "[x] in #alerts", urgency: 1 }, rules), 1)
    compare(Notification.urgencyOf({ appName: "Mail", summary: "x", body: "[", urgency: 1 }, rules), 1)
    compare(Notification.urgencyOf({ appName: "Slack", summary: "[x] in #alerts", urgency: 1 }), 1)
    compare(Notification.durationFor({ appName: "Slack", summary: "[x] in #alerts", urgency: 1, expireTimeout: 1 }, 0, 2, rules), 0)
    compare(Notification.snapshotOf({ appName: "Slack", summary: "[x] in #alerts", urgency: 1 }, 123, rules), {
      app: "Slack", appIcon: "", summary: "[x] in #alerts", body: "", image: "", urgency: 2, timestamp: 123,
    })
  }

  function test_notification_dedup_comes_from_the_first_matching_rule_with_a_group() {
    const rules = Notification.compileRules([
      { match: { app: "^Chromium$", body: "^calendar\\.google\\.com\\n" }, dedup: { group: "calendar", keep: true } },
      { match: { app: "^Slack$", summary: " from Google Calendar$" }, critical: true },
      { match: { app: "^Slack$", summary: " from Google Calendar$" }, dedup: { group: "calendar", keep: false } },
      { match: { app: "^Slack$" }, dedup: { group: "slack", keep: false } },
    ])

    compare(Notification.dedupOf({ appName: "Chromium", body: "calendar.google.com\n09:00 – 09:30" }, rules), { group: "calendar", keep: true })
    compare(Notification.dedupOf({ appName: "Chromium", body: "mail.google.com\ncalendar.google.com" }, rules), null)
    compare(Notification.dedupOf({ appName: "Slack", summary: "[x] from Google Calendar" }, rules), { group: "calendar", keep: false })
    compare(Notification.dedupOf({ appName: "Slack", summary: "[x] in #general" }, rules), { group: "slack", keep: false })
    compare(Notification.dedupOf({ appName: "Slack", summary: "[x] from Google Calendar" }), null)
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
