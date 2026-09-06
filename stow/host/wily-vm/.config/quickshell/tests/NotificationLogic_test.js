import { createRequire } from "node:module"
import { assert, assertEquals, assertMatch } from "jsr:@std/assert"

const Notification = createRequire(import.meta.url)("../plugins/notifications/NotificationLogic.js")

Deno.test("notification snapshots normalize optional fields and preserve supplied time", () => {
  assertEquals(Notification.asString(null), "")
  assertEquals(Notification.asString(4), "4")
  assertEquals(Notification.snapshotOf({ appName: "Mail", urgency: 2 }, 123), {
    app: "Mail", appIcon: "", summary: "", body: "", image: "", urgency: 2, timestamp: 123,
  })
})

Deno.test("notification icon sources preserve schemes and normalize paths", () => {
  assertEquals(Notification.iconSource("/tmp/icon.png"), "file:///tmp/icon.png")
  assertEquals(Notification.iconSource("file:///tmp/icon.png"), "file:///tmp/icon.png")
  assertEquals(Notification.iconSource("image://icon/mail"), "image://icon/mail")
  assertEquals(Notification.iconSource("mail"), "mail")
  assertEquals(Notification.iconSource(null), "")
})

Deno.test("notification duration honors urgency, residency, and bounds", () => {
  const low = 0
  const critical = 2
  assertEquals(Notification.durationFor({ urgency: critical, expireTimeout: 1 }, low, critical), 0)
  assertEquals(Notification.durationFor({ urgency: 1, resident: true }, low, critical), 0)
  assertEquals(Notification.durationFor({ urgency: low, expireTimeout: 1 }, low, critical), 5000)
  assertEquals(Notification.durationFor({ urgency: 1, expireTimeout: 1 }, low, critical), 8000)
  assertEquals(Notification.durationFor({ urgency: 1, expireTimeout: 99999 }, low, critical), 30000)
  assertEquals(Notification.durationFor({ urgency: 1, expireTimeout: "invalid" }, low, critical), 8000)
})

Deno.test("notification display time rejects invalid values", () => {
  assertEquals(Notification.displayTime("invalid"), "")
  assertMatch(Notification.displayTime(0), /\d{2}:\d{2}/)
  assert(Notification.displayTime(0).length > 0)
})
