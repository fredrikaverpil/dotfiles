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

    function test_level_data() {
        const tree = [
            {
                key: "model",
                text: "Model",
                children: [
                    {
                        key: "model.opus",
                        text: "opus",
                        children: []
                    }
                ]
            }
        ];
        return [
            {
                tag: "root",
                tree: tree,
                path: [],
                want: {
                    rows: tree,
                    names: []
                }
            },
            {
                tag: "submenu",
                tree: tree,
                path: ["model"],
                want: {
                    rows: tree[0].children,
                    names: ["Model"]
                }
            },
            {
                tag: "gone",
                tree: tree,
                path: ["effort"],
                want: {
                    rows: [],
                    names: []
                }
            }
        ];
    }

    function test_level(data) {
        const got = Model.level(data.tree, data.path);

        compare(got, data.want);
    }

    function test_scoped_data() {
        const open = {
            key: "open",
            text: "Open"
        };
        const unpick = {
            key: "unpick",
            text: "Unpick"
        };
        const unpickAgain = {
            key: "unpick",
            text: "Unpick listed"
        };
        const search = {
            key: "search",
            text: "Search list"
        };
        const create = {
            key: "new",
            text: "New"
        };
        const separator = {
            isSeparator: true,
            enabled: true
        };
        return [
            {
                tag: "nearest first",
                scopes: [
                    {
                        title: "Row",
                        rows: [open]
                    },
                    {
                        title: "List",
                        rows: [search]
                    },
                    {
                        title: "",
                        rows: [create]
                    }
                ],
                want: {
                    rows: [open, separator, search, separator, create],
                    names: ["List", "Row"]
                }
            },
            {
                tag: "nearer key wins",
                scopes: [
                    {
                        title: "Row",
                        rows: [unpick]
                    },
                    {
                        title: "List",
                        rows: [search, unpickAgain]
                    }
                ],
                want: {
                    rows: [unpick, separator, search],
                    names: ["List", "Row"]
                }
            },
            {
                tag: "empty scope keeps its name",
                scopes: [
                    {
                        title: "Row",
                        rows: [unpick]
                    },
                    {
                        title: "List",
                        rows: [unpickAgain]
                    },
                    {
                        title: "",
                        rows: [create]
                    }
                ],
                want: {
                    rows: [unpick, separator, create],
                    names: ["List", "Row"]
                }
            },
            {
                tag: "none",
                scopes: [],
                want: {
                    rows: [],
                    names: []
                }
            }
        ];
    }

    function test_scoped(data) {
        const got = Model.scoped(data.scopes);

        compare(got, data.want);
    }

    function test_search_data() {
        const opus = {
            key: "model.opus",
            text: "opus",
            detail: "",
            enabled: true,
            isSeparator: false,
            children: []
        };
        const model = {
            key: "model",
            text: "Model",
            detail: "opus",
            enabled: true,
            isSeparator: false,
            children: [opus]
        };
        const rerun = {
            key: "rerun",
            text: "Re-run",
            detail: "",
            keys: ["Ctrl", "R"],
            enabled: true,
            isSeparator: false,
            children: []
        };
        const off = {
            key: "off",
            text: "Re-off",
            detail: "",
            enabled: false,
            isSeparator: false,
            children: []
        };
        const separator = {
            isSeparator: true,
            enabled: true
        };
        const add = {
            key: "add",
            text: "Add a model…",
            detail: "",
            adds: true,
            arg: "",
            enabled: true,
            isSeparator: false,
            children: []
        };
        const rows = [rerun, off, separator, model];
        return [
            {
                tag: "no query",
                rows: rows,
                query: "",
                want: rows
            },
            {
                tag: "direct",
                rows: rows,
                query: "rerun",
                want: [Object.assign({}, rerun, {
                        trail: []
                    })]
            },
            {
                tag: "deeper with path",
                rows: rows,
                query: "opus",
                want: [Object.assign({}, opus, {
                        detail: "Model",
                        trail: ["model"]
                    })]
            },
            {
                tag: "direct before deeper",
                rows: [
                    {
                        key: "tag",
                        text: "Tag",
                        detail: "",
                        enabled: true,
                        isSeparator: false,
                        children: [opus]
                    },
                    model],
                query: "o",
                want: [Object.assign({}, model, {
                        trail: []
                    }), Object.assign({}, opus, {
                        detail: "Tag",
                        trail: ["tag"]
                    }), Object.assign({}, opus, {
                        detail: "Model",
                        trail: ["model"]
                    })]
            },
            {
                tag: "by key",
                rows: rows,
                query: "ctrl+r",
                want: [Object.assign({}, rerun, {
                        trail: []
                    })]
            },
            {
                tag: "adds: a hint without a query",
                rows: [opus, add],
                query: " ",
                want: [opus, Object.assign({}, add, {
                        enabled: false
                    })]
            },
            {
                tag: "adds: what was typed, after matches",
                rows: [opus, add],
                query: " op ",
                want: [Object.assign({}, opus, {
                        trail: []
                    }), Object.assign({}, add, {
                        text: 'Add "op"',
                        arg: "op",
                        trail: []
                    })]
            },
            {
                tag: "adds: not a row's name",
                rows: [opus, add],
                query: "Opus",
                want: [Object.assign({}, opus, {
                        trail: []
                    })]
            },
            {
                tag: "adds: not from deeper levels",
                rows: [Object.assign({}, model, {
                        children: [opus, add]
                    })],
                query: "x",
                want: []
            }
        ];
    }

    function test_search(data) {
        const got = Model.search(data.rows, data.query);

        compare(got, data.want);
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

    function test_hang_data() {
        return [
            {
                tag: "below right",
                anchor: {
                    x: 100,
                    y: 50,
                    width: 0,
                    height: 0
                },
                want: {
                    x: 100,
                    y: 50,
                    above: false
                }
            },
            {
                tag: "flips left at right edge",
                anchor: {
                    x: 900,
                    y: 50,
                    width: 0,
                    height: 0
                },
                want: {
                    x: 700,
                    y: 50,
                    above: false
                }
            },
            {
                tag: "flips above at bottom",
                anchor: {
                    x: 100,
                    y: 550,
                    width: 0,
                    height: 0
                },
                want: {
                    x: 100,
                    y: 450,
                    above: true
                }
            },
            {
                tag: "flips both in bottom right corner",
                anchor: {
                    x: 900,
                    y: 550,
                    width: 0,
                    height: 0
                },
                want: {
                    x: 700,
                    y: 450,
                    above: true
                }
            },
            {
                tag: "kept inside at top left",
                anchor: {
                    x: 2,
                    y: 3,
                    width: 0,
                    height: 0
                },
                want: {
                    x: 8,
                    y: 8,
                    above: false
                }
            },
            {
                tag: "below a chip",
                anchor: {
                    x: 100,
                    y: 50,
                    width: 80,
                    height: 26
                },
                want: {
                    x: 100,
                    y: 76,
                    above: false
                }
            },
            {
                tag: "above a chip at bottom",
                anchor: {
                    x: 100,
                    y: 520,
                    width: 80,
                    height: 26
                },
                want: {
                    x: 100,
                    y: 420,
                    above: true
                }
            },
            {
                tag: "left-aligned to a chip's right edge",
                anchor: {
                    x: 900,
                    y: 50,
                    width: 80,
                    height: 26
                },
                want: {
                    x: 780,
                    y: 76,
                    above: false
                }
            },
            {
                tag: "kept inside when neither side fits",
                anchor: {
                    x: 150,
                    y: 80,
                    width: 0,
                    height: 0
                },
                area: {
                    width: 300,
                    height: 150
                },
                want: {
                    x: 8,
                    y: 8,
                    above: true
                }
            }
        ];
    }

    function test_hang(data) {
        const area = data.area || {
            width: 1000,
            height: 600
        };

        const got = Model.hang(data.anchor, 200, 100, area.width, area.height);

        compare(got, data.want);
    }
}
