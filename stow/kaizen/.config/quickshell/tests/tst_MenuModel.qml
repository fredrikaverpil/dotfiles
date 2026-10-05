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
}
