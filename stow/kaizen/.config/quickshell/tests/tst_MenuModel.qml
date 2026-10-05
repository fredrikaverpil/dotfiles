import QtQuick
import QtTest
import "../modules/menu/MenuModel.js" as Menu

TestCase {
    name: "MenuModel"

    readonly property var items: ({
            apps: {
                label: "Apps",
                provider: "apps"
            },
            learn: {
                label: "Learn"
            },
            "learn.keys": {
                label: "Keys",
                provider: "binds"
            },
            style: {
                label: "Style"
            },
            "style.dark": {
                label: "Dark"
            },
            "style.disabled": {
                label: "Disabled",
                enabled: false
            }
        })

    function test_hierarchy_paths_and_rows_describe_menu_descendants() {
        compare(Menu.childrenOf(items, "root"), ["apps", "learn", "style"]);
        compare(Menu.childrenOf(items, "learn"), ["learn.keys"]);
        compare(Menu.descendantsOf(items, "root"), ["apps", "learn", "learn.keys", "style", "style.dark", "style.disabled"]);
        compare(Menu.pathFrom(items, "learn.keys", "root"), "Learn");
        compare(Menu.rowFor(items, "learn", "root").submenu, true);
        compare(Menu.rowFor(items, "style.disabled", "root").enabled, false);
        compare(Menu.parentLevel("style.dark"), "style");
        compare(Menu.parentLevel("style"), "root");
    }

    function test_row_selection_filters_providers_and_sorts_direct_descendants_first() {
        const apps = detail => [
                {
                    label: "Alacritty",
                    detail,
                    enabled: true,
                    entry: {}
                }
            ];
        const binds = [
            {
                chord: "SUPER + K",
                label: "Keybindings",
                enabled: true
            }
        ];
        const providers = {
            apps,
            binds: () => binds,
            tray: () => [
                    {
                        label: "Network",
                        enabled: true
                    }
                ]
        };

        compare(Menu.rowsFor(items, "learn.keys", "k", providers), binds);
        compare(Menu.rowsFor(items, "apps", "", providers), apps(""));
        compare(Menu.rowsFor(items, "root", "a", providers).map(row => row.label), ["Apps", "Learn", "Dark", "Alacritty"]);
        compare(Menu.rowsFor(items, "root", "", providers).map(row => row.id), ["apps", "learn", "style"]);
        compare(Menu.rowsFor({
            t: {
                label: "Tray",
                provider: "tray"
            }
        }, "t", "net", providers).map(row => row.label), ["Network"]);

        // A level naming a provider nobody registered is empty, not a dead menu.
        compare(Menu.rowsFor({
            gone: {
                label: "Gone",
                provider: "absent"
            }
        }, "gone", "", providers), []);
        compare(Menu.rowsFor(items, "root", "", {}).map(row => row.id), ["apps", "learn", "style"]);
    }

    // QV4 sorts seven or more elements unstably.
    function test_ties_keep_declared_order_beyond_six_rows() {
        const labels = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"].map(letter => "item " + letter);
        const many = {
            many: {
                label: "Many"
            },
            list: {
                label: "List",
                provider: "list"
            }
        };
        labels.forEach((label, index) => many["many." + index] = {
                label: label
            });
        const providers = {
            list: () => labels.map(label => ({
                            label: label,
                            enabled: true
                        }))
        };
        const cases = [
            {
                name: "tree without counts",
                level: "many",
                query: "",
                counts: undefined,
                want: labels
            },
            {
                name: "tree with one launched",
                level: "many",
                query: "",
                counts: {
                    "many.7": 1
                },
                want: [labels[7]].concat(labels.filter((label, index) => index !== 7))
            },
            {
                name: "search",
                level: "many",
                query: "item",
                counts: undefined,
                want: labels
            },
            {
                name: "provider",
                level: "list",
                query: "",
                counts: {},
                want: labels
            }
        ];
        for (const c of cases) {
            const got = Menu.rowsFor(many, c.level, c.query, providers, c.counts).map(row => row.label);
            compare(got, c.want, c.name);
        }
    }

    function test_frecency_reorders_launched_items_ties_keep_declared_order() {
        const providers = {
            apps: detail => [
                    {
                        label: "Alacritty",
                        detail,
                        enabled: true,
                        entry: {
                            id: "alacritty"
                        }
                    }
                ]
        };

        // A launched "style" moves ahead of unlaunched siblings.
        compare(Menu.rowsFor(items, "root", "", providers, {
            style: 3
        })[0].id, "style");
        compare(Menu.rowsFor(items, "root", "", providers, {}).map(row => row.id), ["apps", "learn", "style"]);

        // A provider level: a launched app moves first, without counts the provider's order stays.
        const twoApps = {
            apps: () => [
                    {
                        label: "Alacritty",
                        enabled: true,
                        entry: {
                            id: "alacritty"
                        }
                    },
                    {
                        label: "Zed",
                        enabled: true,
                        entry: {
                            id: "zed"
                        }
                    }
                ]
        };
        compare(Menu.rowsFor(items, "apps", "", twoApps, {
            zed: 2
        }).map(row => row.label), ["Zed", "Alacritty"]);
        compare(Menu.rowsFor(items, "apps", "", twoApps).map(row => row.label), ["Alacritty", "Zed"]);

        // Search: a launched app outranks an unlaunched tree match with the same detail weight.
        compare(Menu.rowsFor(items, "root", "a", providers, {
            alacritty: 1
        }).map(row => row.label), ["Alacritty", "Apps", "Learn", "Dark"]);
    }

    function test_search_ignores_hyphens() {
        const items = {
            wifi: {
                label: "Wi-Fi"
            },
            email: {
                label: "Email"
            }
        };
        const cases = [
            {
                query: "wifi",
                want: ["Wi-Fi"]
            },
            {
                query: "wi-fi",
                want: ["Wi-Fi"]
            },
            {
                query: "e-mail",
                want: ["Email"]
            },
        ];
        for (const c of cases) {
            const got = Menu.rowsFor(items, "root", c.query, {}).map(row => row.label);
            compare(got, c.want, c.query);
        }
    }

    function test_chord_for_names_the_first_bind_running_the_item() {
        const binds = [
            {
                chord: "Mod+Space",
                label: "Menu",
                enabled: true,
                ipc: "menu toggle"
            },
            {
                chord: "XF86AudioPause",
                label: "Play/pause",
                enabled: true,
                ipc: "media playPause"
            },
            {
                chord: "XF86AudioPlay",
                label: "Play/pause",
                enabled: true,
                ipc: "media playPause"
            },
            {
                chord: "Mod+Q",
                label: "Close window",
                enabled: true,
                action: "close-window"
            },
            {
                chord: "Mod+T",
                label: "Terminal",
                enabled: true
            }
        ];
        const cases = [
            {
                name: "ipc",
                item: {
                    ipc: "menu toggle"
                },
                want: "Mod+Space"
            },
            {
                name: "bound twice",
                item: {
                    ipc: "media playPause"
                },
                want: "XF86AudioPause"
            },
            {
                name: "compositor action",
                item: {
                    compositor: "close-window"
                },
                want: "Mod+Q"
            },
            {
                name: "unbound ipc",
                item: {
                    ipc: "lock lock"
                },
                want: undefined
            },
            {
                name: "nothing declared",
                item: {
                    label: "Terminal"
                },
                want: undefined
            }
        ];
        for (const c of cases) {
            compare(Menu.chordFor(c.item, binds), c.want, c.name);
        }
    }

    function test_rows_carry_their_binds_chord_and_match_by_it() {
        const items = {
            session: {
                label: "Session"
            },
            "session.lock": {
                label: "Lock",
                ipc: "lock lock"
            },
            "session.suspend": {
                label: "Suspend"
            }
        };
        const binds = [
            {
                chord: "Super+Alt+L",
                label: "Lock the screen",
                enabled: true,
                ipc: "lock lock"
            }
        ];
        const lock = {
            id: "session.lock",
            label: "Lock",
            icon: undefined,
            detail: "",
            enabled: true,
            entry: null,
            action: null,
            submenu: false,
            chord: "Super+Alt+L"
        };

        compare(Menu.rowsFor(items, "session", "", {}, {}, binds), [lock,
            {
                id: "session.suspend",
                label: "Suspend",
                icon: undefined,
                detail: "",
                enabled: true,
                entry: null,
                action: null,
                submenu: false,
                chord: undefined
            }
        ]);
        compare(Menu.rowsFor(items, "root", "alt+l", {}, {}, binds), [Object.assign({}, lock, {
                detail: "Session"
            })]);
    }
}
