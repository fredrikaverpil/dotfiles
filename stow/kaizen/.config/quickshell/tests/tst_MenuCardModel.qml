import QtQuick
import QtTest
import "../Ui/MenuCardModel.js" as Model

TestCase {
    name: "MenuCardModel"

    function test_step_data() {
        const rows = [
            {
                isSeparator: false
            },
            {
                isSeparator: true
            },
            {
                isSeparator: false
            }
        ];
        return [
            {
                tag: "none forward",
                rows: rows,
                current: -1,
                steps: 1,
                want: 0
            },
            {
                tag: "none backward",
                rows: rows,
                current: -1,
                steps: -1,
                want: 2
            },
            {
                tag: "skips separator",
                rows: rows,
                current: 0,
                steps: 1,
                want: 2
            },
            {
                tag: "wraps forward",
                rows: rows,
                current: 2,
                steps: 1,
                want: 0
            },
            {
                tag: "wraps backward",
                rows: rows,
                current: 0,
                steps: -1,
                want: 2
            },
            {
                tag: "separators only",
                rows: [
                    {
                        isSeparator: true
                    }
                ],
                current: -1,
                steps: 1,
                want: -1
            },
            {
                tag: "empty",
                rows: [],
                current: -1,
                steps: 1,
                want: -1
            },
            {
                tag: "skips disabled",
                rows: [
                    {
                        enabled: true
                    },
                    {
                        enabled: false
                    },
                    {
                        enabled: true
                    }
                ],
                current: 0,
                steps: 1,
                want: 2
            },
            {
                tag: "disabled only",
                rows: [
                    {
                        enabled: false
                    }
                ],
                current: -1,
                steps: 1,
                want: -1
            },
            {
                tag: "page down",
                rows: Array.from({
                    length: 12
                }, () => ({
                            enabled: true
                        })),
                current: 0,
                steps: 10,
                want: 10
            },
            {
                tag: "page up wraps",
                rows: Array.from({
                    length: 12
                }, () => ({
                            enabled: true
                        })),
                current: 2,
                steps: -10,
                want: 4
            }
        ];
    }

    function test_step(data) {
        const index = Model.step(data.rows, data.current, data.steps);

        verify(index === data.want, `${index} !== ${data.want}`);
    }

    function test_matches_data() {
        return [
            {
                tag: "substring",
                text: "Wallpaper (workspace)",
                query: "work",
                want: true
            },
            {
                tag: "case",
                text: "Bluetooth",
                query: "BLUE",
                want: true
            },
            {
                tag: "hyphens",
                text: "Wi-Fi",
                query: "wifi",
                want: true
            },
            {
                tag: "no match",
                text: "Sound",
                query: "mic",
                want: false
            },
            {
                tag: "no text",
                text: undefined,
                query: "a",
                want: false
            }
        ];
    }

    function test_matches(data) {
        const found = Model.matches({
            text: data.text
        }, data.query);

        verify(found === data.want);
    }

    function test_sameRow_data() {
        const entry = {
            text: "Tray"
        };
        return [
            {
                tag: "same object",
                a: entry,
                b: entry,
                want: true
            },
            {
                tag: "same key",
                a: {
                    key: "settings.audio"
                },
                b: {
                    key: "settings.audio"
                },
                want: true
            },
            {
                tag: "other key",
                a: {
                    key: "settings.audio"
                },
                b: {
                    key: "settings.display"
                },
                want: false
            },
            {
                tag: "no key",
                a: {
                    text: "Tray"
                },
                b: {
                    text: "Tray"
                },
                want: false
            },
            {
                tag: "missing row",
                a: entry,
                b: undefined,
                want: false
            }
        ];
    }

    function test_sameRow(data) {
        verify(Model.sameRow(data.a, data.b) === data.want);
    }

    // 200x100 card in a 1000x600 area.
    function test_place_data() {
        return [
            {
                tag: "centered",
                anchor: null,
                want: {
                    x: 400,
                    y: 250
                }
            },
            {
                tag: "below button",
                anchor: {
                    below: true,
                    x: 500,
                    width: 28
                },
                want: {
                    x: 500,
                    y: 0
                }
            },
            {
                tag: "below button at right edge",
                anchor: {
                    below: true,
                    x: 960,
                    width: 28
                },
                want: {
                    x: 792,
                    y: 0
                }
            },
            {
                tag: "submenu right",
                anchor: {
                    x: 100,
                    width: 200,
                    y: 50
                },
                want: {
                    x: 302,
                    y: 44
                }
            },
            {
                tag: "submenu flips left",
                anchor: {
                    x: 700,
                    width: 200,
                    y: 50
                },
                want: {
                    x: 498,
                    y: 44
                }
            },
            {
                tag: "submenu clamped to top",
                anchor: {
                    x: 100,
                    width: 200,
                    y: 2
                },
                want: {
                    x: 302,
                    y: 0
                }
            },
            {
                tag: "submenu clamped above bottom",
                anchor: {
                    x: 100,
                    width: 200,
                    y: 580
                },
                want: {
                    x: 302,
                    y: 492
                }
            }
        ];
    }

    function test_place(data) {
        compare(Model.place(data.anchor, 200, 100, 1000, 600), data.want);
    }
}
