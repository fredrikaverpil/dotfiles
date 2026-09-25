import QtQuick
import QtTest
import "../plugins/notifications/NotificationModel.js" as Notification

TestCase {
  name: "NotificationModel"

  readonly property var record: ({
    key: "1", app: "Mail", appIcon: "mail", summary: "Hi", body: "Body", image: "", icon: "", urgency: 1, timestamp: 10,
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
      { app: "Mail", appIcon: "mail", summary: "New", body: "Body", image: "", icon: "", urgency: 1, timestamp: 10 },
      saved,
    ])
  }

  function test_popup_replacement_removal_and_ipc_dnd_values_are_deterministic() {
    const replacement = Object.assign({}, record, { summary: "Updated" })
    compare(Notification.replacePopup([record], replacement), [replacement])
    compare(Notification.replacePopup([], replacement), [])
    compare(Notification.withoutRecord([record, replacement], "1"), [])
    compare(Notification.withoutIndex([record, replacement], 0), [replacement])
    compare(Notification.withoutIndex([record], 1), [record])
    compare(Notification.withoutIndex([record], -1), [record])
    for (const value of ["true", "1", "on", "yes", "YES"]) compare(Notification.dndValue(value), true)
    for (const value of ["", "false", "0", "off", "no"]) compare(Notification.dndValue(value), false)
  }

  function test_popup_selection_steps_wrap_and_follow_removal() {
    const rows = [{ key: "3" }, { key: "2" }, { key: "1" }]
    verify(Notification.step(2, 1, 3) === 0)
    verify(Notification.step(0, -1, 3) === 2)
    verify(Notification.step(0, 1, 0) === 0)
    compare(Notification.stepKey(rows, "3", 1), "2")
    compare(Notification.stepKey(rows, "1", 1), "3")
    compare(Notification.stepKey(rows, "3", -1), "1")
    compare(Notification.stepKey([], "3", 1), "")
    compare(Notification.keyAfter(rows, "3"), "2")
    compare(Notification.keyAfter(rows, "1"), "2")
    compare(Notification.keyAfter([{ key: "1" }], "1"), "")
    compare(Notification.keyAfter(rows, "9"), "")
  }
}
