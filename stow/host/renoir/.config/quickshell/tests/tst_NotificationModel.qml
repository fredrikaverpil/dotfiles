import QtQuick
import QtTest
import "../plugins/notifications/NotificationModel.js" as Notification

TestCase {
  name: "NotificationModel"

  readonly property var record: ({
    key: "1", app: "Mail", appIcon: "mail", summary: "Hi", body: "Body", image: "", urgency: 1, timestamp: 10,
  })

  function test_notification_state_loading_rejects_invalid_data_and_caps_history() {
    compare(Notification.loadedState("invalid", 2), { valid: false, doNotDisturb: false, history: [] })
    compare(Notification.loadedState('{"doNotDisturb":true,"history":[1,2,3]}', 2), {
      valid: true, doNotDisturb: true, history: [1, 2],
    })
    compare(Notification.stateText(true, [record]), JSON.stringify({ version: 1, doNotDisturb: true, history: [record] }, null, 2) + "\n")
  }

  function test_notification_history_skips_transient_records_and_keeps_newest_entries() {
    compare(Notification.historyWith([record], { transient: true }, 2), [record])
    const newer = Object.assign({}, record, { key: "2", summary: "New" })
    const saved = Notification.savedRecord(record)
    compare(Notification.historyWith([saved, Object.assign({}, saved, { summary: "Old" })], newer, 2), [
      { app: "Mail", appIcon: "mail", summary: "New", body: "Body", image: "", urgency: 1, timestamp: 10 },
      saved,
    ])
  }

  function test_popup_replacement_removal_and_ipc_dnd_values_are_deterministic() {
    const replacement = Object.assign({}, record, { summary: "Updated" })
    compare(Notification.replacePopup([record], replacement), [replacement])
    compare(Notification.replacePopup([], replacement), [])
    compare(Notification.withoutRecord([record, replacement], "1"), [])
    for (const value of ["true", "1", "on", "yes", "YES"]) compare(Notification.dndValue(value), true)
    for (const value of ["", "false", "0", "off", "no"]) compare(Notification.dndValue(value), false)
  }
}
