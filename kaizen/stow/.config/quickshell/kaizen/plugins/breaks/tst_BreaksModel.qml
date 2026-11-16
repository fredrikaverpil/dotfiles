import QtQuick
import QtTest
import "BreaksModel.js" as Model

TestCase {
    name: "BreaksModel"

    readonly property int minute: 60 * 1000

    readonly property var eyes: ({
            id: "eyes",
            everyMinutes: 20,
            icon: "\u{F06D0}",
            title: "Look into the distance",
            details: ["20 s at something 6 m away"],
            seconds: 20
        })
    readonly property var move: ({
            id: "move",
            everyMinutes: 30,
            icon: "\u{F070E}",
            title: "Stand up and move",
            details: ["10 squats", "Shoulder rolls", "Hip-flexor stretch", "Walk for 2 min"],
            seconds: 0
        })
    readonly property var reminders: [eyes, move]

    function test_settings_data() {
        return [
            {
                tag: "defaults",
                config: {},
                want: {
                    idleMinutes: 5,
                    reminders: [eyes, move]
                }
            },
            {
                tag: "no config",
                config: null,
                want: {
                    idleMinutes: 5,
                    reminders: [eyes, move]
                }
            },
            {
                tag: "set",
                config: {
                    idleMinutes: 3,
                    reminders: [
                        {
                            id: "water",
                            everyMinutes: 45,
                            icon: "W",
                            title: "Drink water",
                            detail: "A full glass",
                            seconds: 10
                        },
                    ]
                },
                want: {
                    idleMinutes: 3,
                    reminders: [
                        {
                            id: "water",
                            everyMinutes: 45,
                            icon: "W",
                            title: "Drink water",
                            details: ["A full glass"],
                            seconds: 10
                        },
                    ]
                }
            },
            {
                tag: "details over detail",
                config: {
                    reminders: [
                        {
                            id: "a",
                            everyMinutes: 10,
                            title: "A",
                            detail: "ignored",
                            details: ["x", 3, "", "y"]
                        },
                    ]
                },
                want: {
                    idleMinutes: 5,
                    reminders: [
                        {
                            id: "a",
                            everyMinutes: 10,
                            icon: "\u{F0176}",
                            title: "A",
                            details: ["x", "y"],
                            seconds: 0
                        },
                    ]
                }
            },
            {
                tag: "empty list: no reminders",
                config: {
                    reminders: []
                },
                want: {
                    idleMinutes: 5,
                    reminders: []
                }
            },
            {
                tag: "invalid",
                config: {
                    idleMinutes: 0,
                    reminders: [null, "x",
                        {
                            everyMinutes: 10,
                            title: "no id"
                        },
                        {
                            id: "b",
                            everyMinutes: "10",
                            title: "B"
                        },
                        {
                            id: "c",
                            everyMinutes: 10
                        },
                        {
                            id: "d",
                            everyMinutes: 10,
                            icon: 3,
                            title: "D",
                            seconds: -1
                        },
                        {
                            id: "d",
                            everyMinutes: 20,
                            title: "repeated id"
                        },
                    ]
                },
                want: {
                    idleMinutes: 5,
                    reminders: [
                        {
                            id: "d",
                            everyMinutes: 10,
                            icon: "\u{F0176}",
                            title: "D",
                            details: [],
                            seconds: 0
                        },
                    ]
                }
            },
        ];
    }

    function test_settings(data) {
        compare(Model.settings(data.config), data.want);
    }

    function test_duration_data() {
        return [
            {
                tag: "zero",
                ms: 0,
                want: "0m"
            },
            {
                tag: "negative",
                ms: -5000,
                want: "0m"
            },
            {
                tag: "rounds down",
                ms: 32 * minute + 59000,
                want: "32m"
            },
            {
                tag: "whole hour",
                ms: 60 * minute,
                want: "1h"
            },
            {
                tag: "hour and minutes",
                ms: 65 * minute,
                want: "1h 5m"
            },
        ];
    }

    function test_duration(data) {
        compare(Model.duration(data.ms), data.want);
    }

    function test_reminders_due_data() {
        return [
            {
                tag: "before",
                elapsed: 59 * minute,
                want: 0
            },
            {
                tag: "at",
                elapsed: 60 * minute,
                want: 1
            },
            {
                tag: "repeats",
                elapsed: 125 * minute,
                want: 2
            },
        ];
    }

    function test_reminders_due(data) {
        verify(Model.remindersDue(data.elapsed, 60 * minute) === data.want);
    }

    function test_state_data() {
        return [
            {
                tag: "idle",
                active: false,
                elapsed: 0,
                want: "idle"
            },
            {
                tag: "a shorter one due is still active",
                active: true,
                elapsed: 25 * minute,
                want: "active"
            },
            {
                tag: "due",
                active: true,
                elapsed: 30 * minute,
                want: "due"
            },
            {
                tag: "idle while holding",
                active: false,
                holding: true,
                elapsed: 0,
                want: "idle"
            },
            {
                tag: "holding",
                active: true,
                holding: true,
                elapsed: 40 * minute,
                want: "holding"
            },
        ];
    }

    function test_state_no_reminders() {
        compare(Model.state(true, 90 * minute, [], false), "active");
    }

    function test_state(data) {
        compare(Model.state(data.active, data.elapsed, reminders, data.holding || false), data.want);
    }

    function test_indicator_data() {
        return [
            {
                tag: "idle",
                state: "idle",
                elapsed: 0,
                want: {
                    icon: "\u{F051B}",
                    text: "0m",
                    role: "off"
                }
            },
            {
                tag: "active",
                state: "active",
                elapsed: 32 * minute,
                want: {
                    icon: "\u{F051B}",
                    text: "32m",
                    role: "fg"
                }
            },
            {
                tag: "due",
                state: "due",
                elapsed: 65 * minute,
                want: {
                    icon: "\u{F0176}",
                    text: "1h 5m",
                    role: "wood"
                }
            },
            {
                tag: "holding",
                state: "holding",
                elapsed: 32 * minute,
                want: {
                    icon: "\u{F051E}",
                    text: "32m",
                    role: "rose"
                }
            },
        ];
    }

    function test_indicator(data) {
        compare(Model.indicator(data.state, data.elapsed), data.want);
    }

    function test_status_data() {
        return [
            {
                tag: "idle",
                state: "idle",
                elapsed: 0,
                want: "No active session"
            },
            {
                tag: "active",
                state: "active",
                elapsed: 32 * minute,
                want: "Active for 32m"
            },
            {
                tag: "holding",
                state: "holding",
                elapsed: 32 * minute,
                want: "Active for 32m · holding"
            },
        ];
    }

    function test_status(data) {
        compare(Model.status(data.state, data.elapsed), data.want);
    }

    function test_longest_data() {
        return [
            {
                tag: "none",
                reminders: [],
                want: null
            },
            {
                tag: "longest",
                reminders: [eyes, move],
                want: "move"
            },
            {
                tag: "first of equals",
                reminders: [move,
                    {
                        id: "other",
                        everyMinutes: 30
                    }
                ],
                want: "move"
            },
        ];
    }

    function test_longest(data) {
        const got = Model.longest(data.reminders);
        compare(got ? got.id : null, data.want);
    }

    function test_pick_data() {
        return [
            {
                tag: "nothing due",
                elapsed: 19 * minute,
                shown: {},
                want: {
                    reminder: null,
                    shown: {
                        eyes: 0,
                        move: 0
                    }
                }
            },
            {
                tag: "one due",
                elapsed: 20 * minute,
                shown: {},
                want: {
                    reminder: "eyes",
                    shown: {
                        eyes: 1,
                        move: 0
                    }
                }
            },
            {
                tag: "already shown",
                elapsed: 25 * minute,
                shown: {
                    eyes: 1
                },
                want: {
                    reminder: null,
                    shown: {
                        eyes: 1,
                        move: 0
                    }
                }
            },
            {
                tag: "coinciding: longest wins, both marked",
                elapsed: 60 * minute,
                shown: {
                    eyes: 2,
                    move: 1
                },
                want: {
                    reminder: "move",
                    shown: {
                        eyes: 3,
                        move: 2
                    }
                }
            },
            {
                tag: "pending after a hold: longest wins, all marked",
                elapsed: 70 * minute,
                shown: {
                    eyes: 1,
                    move: 0
                },
                want: {
                    reminder: "move",
                    shown: {
                        eyes: 3,
                        move: 2
                    }
                }
            },
        ];
    }

    function test_pick(data) {
        const got = Model.pick(reminders, data.elapsed, data.shown);
        compare({
            reminder: got.reminder ? got.reminder.id : null,
            shown: got.shown
        }, data.want);
    }

    function test_detail_data() {
        return [
            {
                tag: "first",
                reminder: move,
                n: 0,
                want: "10 squats"
            },
            {
                tag: "next",
                reminder: move,
                n: 1,
                want: "Shoulder rolls"
            },
            {
                tag: "wraps",
                reminder: move,
                n: 5,
                want: "Shoulder rolls"
            },
            {
                tag: "single",
                reminder: {
                    details: ["A full glass"]
                },
                n: 3,
                want: "A full glass"
            },
            {
                tag: "none",
                reminder: {
                    details: []
                },
                n: 0,
                want: ""
            },
        ];
    }

    function test_detail(data) {
        compare(Model.detail(data.reminder, data.n), data.want);
    }

    function test_restored_data() {
        const now = 1000 * minute;
        const idle = 5 * minute;
        const saved = o => JSON.stringify(Object.assign({
                version: 1,
                holding: false,
                owned: false,
                rotation: {
                    move: 3
                },
                sessionStart: now - 40 * minute,
                shown: {
                    eyes: 1,
                    move: 1
                },
                seen: now - minute
            }, o));
        return [
            {
                tag: "resumes within idle",
                raw: saved({}),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        move: 3
                    },
                    sessionStart: now - 40 * minute,
                    shown: {
                        eyes: 1,
                        move: 1
                    }
                }
            },
            {
                tag: "seen idle ago: new session",
                raw: saved({
                    seen: now - idle
                }),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        move: 3
                    },
                    sessionStart: 0,
                    shown: {}
                }
            },
            {
                tag: "seen in the future: new session",
                raw: saved({
                    seen: now + minute
                }),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        move: 3
                    },
                    sessionStart: 0,
                    shown: {}
                }
            },
            {
                tag: "no session",
                raw: saved({
                    sessionStart: 0,
                    shown: {}
                }),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        move: 3
                    },
                    sessionStart: 0,
                    shown: {}
                }
            },
            {
                tag: "owned only while holding",
                raw: saved({
                    owned: true
                }),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        move: 3
                    },
                    sessionStart: now - 40 * minute,
                    shown: {
                        eyes: 1,
                        move: 1
                    }
                }
            },
            {
                tag: "holding",
                raw: saved({
                    holding: true,
                    owned: true,
                    sessionStart: 0,
                    seen: 0
                }),
                want: {
                    valid: true,
                    holding: true,
                    owned: true,
                    rotation: {
                        move: 3
                    },
                    sessionStart: 0,
                    shown: {}
                }
            },
            {
                tag: "bad counts dropped",
                raw: saved({
                    rotation: {
                        a: -1,
                        b: 1.5,
                        c: "2",
                        d: 2
                    },
                    shown: [1]
                }),
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {
                        d: 2
                    },
                    sessionStart: now - 40 * minute,
                    shown: {}
                }
            },
            {
                tag: "no file",
                raw: "",
                want: {
                    valid: true,
                    holding: false,
                    owned: false,
                    rotation: {},
                    sessionStart: 0,
                    shown: {}
                }
            },
            {
                tag: "not JSON",
                raw: "{",
                want: {
                    valid: false,
                    holding: false,
                    owned: false,
                    rotation: {},
                    sessionStart: 0,
                    shown: {}
                }
            },
        ];
    }

    function test_restored(data) {
        compare(Model.restored(data.raw, 1000 * minute, 5 * minute), data.want);
    }

    function test_state_text_round_trip() {
        const now = 1000 * minute;
        const text = Model.stateText(true, true, {
            move: 2
        }, now - 10 * minute, {
            eyes: 0
        }, now);
        compare(Model.restored(text, now, 5 * minute), {
            valid: true,
            holding: true,
            owned: true,
            rotation: {
                move: 2
            },
            sessionStart: now - 10 * minute,
            shown: {
                eyes: 0
            }
        });
    }
}
