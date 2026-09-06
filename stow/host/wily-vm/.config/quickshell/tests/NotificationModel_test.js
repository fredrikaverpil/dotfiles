import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Notification = createRequire(import.meta.url)("../plugins/notifications/NotificationModel.js")

const record = {
  key: "1", app: "Mail", appIcon: "mail", summary: "Hi", body: "Body", image: "", urgency: 1, timestamp: 10,
}

Deno.test("notification state loading rejects invalid data and caps history", () => {
  assertEquals(Notification.loadedState("invalid", 2), { valid: false, doNotDisturb: false, history: [] })
  assertEquals(Notification.loadedState('{"doNotDisturb":true,"history":[1,2,3]}', 2), {
    valid: true, doNotDisturb: true, history: [1, 2],
  })
  assertEquals(Notification.stateText(true, [record]), JSON.stringify({ version: 1, doNotDisturb: true, history: [record] }, null, 2) + "\n")
})

Deno.test("notification history skips transient records and keeps newest entries", () => {
  assertEquals(Notification.historyWith([record], { transient: true }, 2), [record])
  const newer = { ...record, key: "2", summary: "New" }
  const saved = Notification.savedRecord(record)
  assertEquals(Notification.historyWith([saved, { ...saved, summary: "Old" }], newer, 2), [
    { app: "Mail", appIcon: "mail", summary: "New", body: "Body", image: "", urgency: 1, timestamp: 10 },
    saved,
  ])
})

Deno.test("popup replacement, removal, and IPC DND values are deterministic", () => {
  const replacement = { ...record, summary: "Updated" }
  assertEquals(Notification.replacePopup([record], replacement), [replacement])
  assertEquals(Notification.replacePopup([], replacement), [])
  assertEquals(Notification.withoutRecord([record, replacement], "1"), [])
  for (const value of ["true", "1", "on", "yes", "YES"]) assertEquals(Notification.dndValue(value), true)
  for (const value of ["", "false", "0", "off", "no"]) assertEquals(Notification.dndValue(value), false)
})
