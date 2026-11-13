import QtQuick
import QtTest
import "../modules/services/audio/AudioModel.js" as Audio

TestCase {
    name: "AudioModel"

    // Trimmed from `pw-dump 47 93` on a ThinkPad: an HDA card and a USB camera's. Headphones
    // share the Speaker's device here, as on cards with one sink for both.
    readonly property var dump: [
        {
            id: 47,
            type: "PipeWire:Interface:Device",
            info: {
                params: {
                    EnumRoute: [
                        {
                            direction: "Output",
                            name: "[Out] HDMI3",
                            available: "no",
                            devices: [0]
                        },
                        {
                            direction: "Output",
                            name: "[Out] HDMI1",
                            available: "yes",
                            devices: [2]
                        },
                        {
                            direction: "Output",
                            name: "[Out] Speaker",
                            available: "unknown",
                            devices: [3]
                        },
                        {
                            direction: "Output",
                            name: "[Out] Headphones",
                            available: "no",
                            devices: [3]
                        },
                        {
                            direction: "Input",
                            name: "[In] Mic2",
                            available: "no",
                            devices: [4]
                        },
                        {
                            direction: "Input",
                            name: "[In] Mic1",
                            available: "unknown",
                            devices: [5]
                        }
                    ]
                }
            }
        },
        {
            id: 93,
            type: "PipeWire:Interface:Device",
            info: {
                params: {}
            }
        },
        {
            id: 64,
            type: "PipeWire:Interface:Node",
            info: {}
        }
    ]

    function node(props, isSink) {
        return {
            properties: props,
            isSink: isSink
        };
    }

    function test_unplugged() {
        const cases = [
            {
                name: "a device with a plugged route stays plugged",
                dump: dump,
                want: ["47:0:Output", "47:4:Input"]
            },
            {
                name: "no dump",
                dump: null,
                want: []
            },
            {
                name: "a device without routes",
                dump: [dump[1]],
                want: []
            }
        ];
        for (const c of cases)
            compare(Audio.unplugged(c.dump), c.want, c.name);
    }

    function test_is_unplugged() {
        const keys = Audio.unplugged(dump);
        const cases = [
            {
                name: "an empty HDMI port",
                node: node({
                    "device.id": "47",
                    "card.profile.device": "0"
                }, true),
                want: true
            },
            {
                name: "the headset mic's empty jack",
                node: node({
                    "device.id": "47",
                    "card.profile.device": "4"
                }, false),
                want: true
            },
            {
                name: "a source on an output's device",
                node: node({
                    "device.id": "47",
                    "card.profile.device": "0"
                }, false),
                want: false
            },
            {
                name: "the speaker, one route unknown",
                node: node({
                    "device.id": "47",
                    "card.profile.device": "3"
                }, true),
                want: false
            },
            {
                name: "a node without a card",
                node: node({}, true),
                want: false
            },
            {
                name: "no node",
                node: null,
                want: false
            }
        ];
        for (const c of cases)
            compare(Audio.isUnplugged(keys, c.node), c.want, c.name);
    }

    function test_cards() {
        const nodes = [node({
                "device.api": "alsa",
                "device.id": "93"
            }, false), node({
                "device.api": "alsa",
                "device.id": "47"
            }, true), node({
                "device.api": "alsa",
                "device.id": "47"
            }, false), node({
                "device.api": "bluez5",
                "device.id": "99"
            }, true), node({
                "device.api": "alsa"
            }, true), null];
        compare(Audio.cards(nodes), ["47", "93"]);
    }
}
