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

  function test_notification_icon_sources_preserve_schemes_and_normalize_paths() {
    compare(Notification.iconSource("/tmp/icon.png"), "file:///tmp/icon.png")
    compare(Notification.iconSource("file:///tmp/icon.png"), "file:///tmp/icon.png")
    compare(Notification.iconSource("image://icon/mail"), "image://icon/mail")
    compare(Notification.iconSource("mail"), "mail")
    compare(Notification.iconSource(null), "")
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
  }
}
