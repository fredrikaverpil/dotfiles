import QtQuick
import QtTest
import "../modules/notifications/NotificationLogic.js" as Logic
import "../modules/notifications/NotificationModel.js" as Notification

TestCase {
    name: "NotificationModel"

    function test_saved_records_keep_every_snapshot_field() {
        const snapshot = Logic.snapshotOf({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1
        }, 123, Logic.compileRules([
            {
                match: {
                    app: "^Slack$"
                },
                border: "rose",
                borderAnimation: "glow",
                actions: [
                    {
                        label: "Investigate",
                        command: ["investigate", "draft"]
                    }
                ]
            }
        ]));
        compare(Notification.savedRecord(Object.assign({
            key: "1",
            notification: {},
            duration: 0
        }, snapshot)), snapshot);
    }

    readonly property var record: ({
            key: "1",
            app: "Mail",
            appIcon: "mail",
            summary: "Hi",
            body: "Body",
            image: "",
            icon: "",
            badgeIcon: "",
            badgeEmoji: "",
            border: "rose",
            borderAnimation: "glow",
            actions: [
                {
                    text: "Investigate",
                    command: ["investigate", "draft"],
                    env: {}
                }
            ],
            urgency: 1,
            timestamp: 10
        })

    function test_notification_state_loading_rejects_invalid_data_and_caps_history() {
        compare(Notification.loadedState("invalid", 2), {
            valid: false,
            doNotDisturb: false,
            dndSince: 0,
            history: []
        });
        compare(Notification.loadedState('{"doNotDisturb":true,"dndSince":5,"history":[1,2,3]}', 2), {
            valid: true,
            doNotDisturb: true,
            dndSince: 5,
            history: [1, 2]
        });
        compare(Notification.stateText(true, [record], 5), JSON.stringify({
            version: 1,
            doNotDisturb: true,
            dndSince: 5,
            history: [record]
        }, null, 2) + "\n");
    }

    function test_notification_history_skips_transient_records_and_keeps_newest_entries() {
        compare(Notification.historyWith([record], {
            transient: true
        }, 2, 2), [record]);
        const newer = Object.assign({}, record, {
            key: "2",
            summary: "New"
        });
        const saved = Notification.savedRecord(record);
        compare(Notification.historyWith([saved, Object.assign({}, saved, {
                summary: "Old"
            })], newer, 2, 2), [
            {
                app: "Mail",
                appIcon: "mail",
                summary: "New",
                body: "Body",
                image: "",
                icon: "",
                badgeIcon: "",
                badgeEmoji: "",
                border: "rose",
                borderAnimation: "glow",
                actions: [
                    {
                        text: "Investigate",
                        command: ["investigate", "draft"],
                        env: {}
                    }
                ],
                urgency: 1,
                timestamp: 10
            },
            saved,]);
    }

    function test_notification_history_keeps_critical_first_and_drops_them_last() {
        const saved = Notification.savedRecord(record);
        const critical = Object.assign({}, saved, {
            summary: "Critical",
            urgency: 2
        });
        const newer = Object.assign({}, record, {
            summary: "New"
        });
        compare(Notification.historyWith([critical, saved], newer, 2, 2), [critical, Notification.savedRecord(newer)]);
        compare(Notification.historyWith([saved], Object.assign({}, critical, {
            key: "2"
        }), 3, 2), [critical, saved]);
    }

    function test_popup_replacement_removal_and_ipc_dnd_values_are_deterministic() {
        const replacement = Object.assign({}, record, {
            summary: "Updated"
        });
        compare(Notification.replacePopup([record], replacement), [replacement]);
        compare(Notification.replacePopup([], replacement), []);
        compare(Notification.withoutRecord([record, replacement], "1"), []);
        compare(Notification.withoutIndex([record, replacement], 0), [replacement]);
        compare(Notification.withoutIndex([record], 1), [record]);
        compare(Notification.withoutIndex([record], -1), [record]);
        for (const value of ["true", "1", "on", "yes", "YES"])
            compare(Notification.dndValue(value), true);
        for (const value of ["", "false", "0", "off", "no"])
            compare(Notification.dndValue(value), false);
    }

    function test_dnd_hold_data() {
        return [
            {
                tag: "first hold turns DnD on and owns it",
                state: {
                    doNotDisturb: false,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: true,
                want: {
                    doNotDisturb: true,
                    holds: ["recording"],
                    owned: true
                }
            },
            {
                tag: "hold leaves DnD set by hand unowned",
                state: {
                    doNotDisturb: true,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: true,
                want: {
                    doNotDisturb: true,
                    holds: ["recording"],
                    owned: false
                }
            },
            {
                tag: "second hold keeps ownership",
                state: {
                    doNotDisturb: true,
                    holds: ["recording"],
                    owned: true
                },
                reason: "sharing",
                on: true,
                want: {
                    doNotDisturb: true,
                    holds: ["recording", "sharing"],
                    owned: true
                }
            },
            {
                tag: "repeated hold is held once",
                state: {
                    doNotDisturb: true,
                    holds: ["sharing"],
                    owned: true
                },
                reason: "sharing",
                on: true,
                want: {
                    doNotDisturb: true,
                    holds: ["sharing"],
                    owned: true
                }
            },
            {
                tag: "release with holds left keeps DnD on",
                state: {
                    doNotDisturb: true,
                    holds: ["recording", "sharing"],
                    owned: true
                },
                reason: "recording",
                on: false,
                want: {
                    doNotDisturb: true,
                    holds: ["sharing"],
                    owned: true
                }
            },
            {
                tag: "last release turns owned DnD off",
                state: {
                    doNotDisturb: true,
                    holds: ["sharing"],
                    owned: true
                },
                reason: "sharing",
                on: false,
                want: {
                    doNotDisturb: false,
                    holds: [],
                    owned: false
                }
            },
            {
                tag: "last release leaves unowned DnD on",
                state: {
                    doNotDisturb: true,
                    holds: ["sharing"],
                    owned: false
                },
                reason: "sharing",
                on: false,
                want: {
                    doNotDisturb: true,
                    holds: [],
                    owned: false
                }
            },
            {
                tag: "release without a hold changes nothing",
                state: {
                    doNotDisturb: false,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: false,
                want: {
                    doNotDisturb: false,
                    holds: [],
                    owned: false
                }
            }
        ];
    }

    function test_dnd_hold(data) {
        compare(Notification.dndHold(data.state, data.reason, data.on), data.want);
    }

    function test_popup_selection_steps_wrap_and_follow_removal() {
        const rows = [
            {
                key: "3"
            },
            {
                key: "2"
            },
            {
                key: "1"
            }
        ];
        verify(Notification.step(2, 1, 3) === 0);
        verify(Notification.step(0, -1, 3) === 2);
        verify(Notification.step(0, 1, 0) === 0);
        compare(Notification.stepKey(rows, "3", 1), "2");
        compare(Notification.stepKey(rows, "1", 1), "3");
        compare(Notification.stepKey(rows, "3", -1), "1");
        compare(Notification.stepKey([], "3", 1), "");
        compare(Notification.keyAfter(rows, "3"), "2");
        compare(Notification.keyAfter(rows, "1"), "2");
        compare(Notification.keyAfter([
            {
                key: "1"
            }
        ], "1"), "");
        compare(Notification.keyAfter(rows, "9"), "");
    }
}
