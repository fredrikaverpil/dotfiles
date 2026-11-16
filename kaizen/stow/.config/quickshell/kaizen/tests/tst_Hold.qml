import QtQuick
import QtTest
import "../Ui/Hold.js" as Hold

TestCase {
    name: "Hold"

    function test_hold_data() {
        return [
            {
                tag: "first hold turns it on and owns it",
                state: {
                    on: false,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: true,
                want: {
                    on: true,
                    holds: ["recording"],
                    owned: true
                }
            },
            {
                tag: "hold leaves it set by hand unowned",
                state: {
                    on: true,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: true,
                want: {
                    on: true,
                    holds: ["recording"],
                    owned: false
                }
            },
            {
                tag: "second hold keeps ownership",
                state: {
                    on: true,
                    holds: ["recording"],
                    owned: true
                },
                reason: "sharing",
                on: true,
                want: {
                    on: true,
                    holds: ["recording", "sharing"],
                    owned: true
                }
            },
            {
                tag: "repeated hold is held once",
                state: {
                    on: true,
                    holds: ["sharing"],
                    owned: true
                },
                reason: "sharing",
                on: true,
                want: {
                    on: true,
                    holds: ["sharing"],
                    owned: true
                }
            },
            {
                tag: "release with holds left keeps it on",
                state: {
                    on: true,
                    holds: ["recording", "sharing"],
                    owned: true
                },
                reason: "recording",
                on: false,
                want: {
                    on: true,
                    holds: ["sharing"],
                    owned: true
                }
            },
            {
                tag: "last release turns it off when owned",
                state: {
                    on: true,
                    holds: ["sharing"],
                    owned: true
                },
                reason: "sharing",
                on: false,
                want: {
                    on: false,
                    holds: [],
                    owned: false
                }
            },
            {
                tag: "last release leaves it on when unowned",
                state: {
                    on: true,
                    holds: ["sharing"],
                    owned: false
                },
                reason: "sharing",
                on: false,
                want: {
                    on: true,
                    holds: [],
                    owned: false
                }
            },
            {
                tag: "release without a hold changes nothing",
                state: {
                    on: false,
                    holds: [],
                    owned: false
                },
                reason: "recording",
                on: false,
                want: {
                    on: false,
                    holds: [],
                    owned: false
                }
            }
        ];
    }

    function test_hold(data) {
        compare(Hold.hold(data.state, data.reason, data.on), data.want);
    }

    function test_flag_data() {
        return ["true", "1", "on", "yes", "YES"].map(value => ({
                    tag: value,
                    value: value,
                    want: true
                })).concat(["", "false", "0", "off", "no"].map(value => ({
                    tag: value || "empty",
                    value: value,
                    want: false
                })));
    }

    function test_flag(data) {
        compare(Hold.flag(data.value), data.want);
    }
}
